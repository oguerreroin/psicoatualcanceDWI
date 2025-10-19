<#
Small deployment helper: builds the WAR, redeploys it to local Tomcat, posts a test Cita and queries the MySQL container.
Run from repo root in PowerShell (pwsh) with: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\deploy-and-test.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

try {
    $RepoRoot = (Get-Location).Path
    Write-Host "Repo root: $RepoRoot"

    $ProjectDir = Join-Path $RepoRoot 'java-jsp-tomcat-project'
    $Catalina = Join-Path $RepoRoot '.local\tomcat\apache-tomcat-9.0.84'
    $WarSrc = Join-Path $ProjectDir 'target\java-jsp-tomcat-project-1.0-SNAPSHOT.war'
    $WarDst = Join-Path $Catalina 'webapps\java-jsp-tomcat-project-1.0-SNAPSHOT.war'

    # Select maven executable: prefer mvnw if present
    $mvnw = Join-Path $ProjectDir 'mvnw.cmd'
    if (Test-Path $mvnw) { $MvnCmd = $mvnw } else { $MvnCmd = 'mvn' }

    Write-Host "Using Maven command: $MvnCmd"
    if ($MvnCmd -eq 'mvn') {
        if (-not (Get-Command mvn -ErrorAction SilentlyContinue)) {
            Write-Error "mvn not found. Please install Maven or add it to PATH, or include a mvnw wrapper in the project."; exit 1
        }
    }

    # 1) Build (force update of dependencies and package)
    Write-Host "Building project (forcing dependency update)... (this may take a minute)"
    Push-Location $ProjectDir
    & $MvnCmd -U -DskipTests clean package
    $buildExit = $LASTEXITCODE
    Pop-Location
    if ($buildExit -ne 0) { Write-Error "Maven build failed (exit $buildExit). Aborting."; exit $buildExit }
    if (-not (Test-Path $WarSrc)) { Write-Error "Expected WAR not found at $WarSrc"; exit 1 }
    Write-Host "WAR built: $WarSrc"

    # 1.5 Force-verify WAR contents: ensure repository classes and mysql connector are packaged
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $needFix = $false
    $classEntry = 'WEB-INF/classes/com/psicoatualcance/repository/CitaRepositoryMySQL.class'
    $connectorPattern = 'WEB-INF/lib/mysql-connector-j'
    $hasClass = $false; $hasConnector = $false
    $zip = [System.IO.Compression.ZipFile]::OpenRead($WarSrc)
    try {
        foreach ($e in $zip.Entries) {
            if ($e.FullName -eq $classEntry) { $hasClass = $true }
            if ($e.FullName -like "$connectorPattern*") { $hasConnector = $true }
        }
    } finally { $zip.Dispose() }

    if (-not $hasClass) { Write-Warning "Repository class not found inside WAR: $classEntry"; $needFix = $true }
    if (-not $hasConnector) { Write-Warning "MySQL connector jar not found inside WAR (WEB-INF/lib)"; $needFix = $true }

    if ($needFix) {
        Write-Host "Repairing WAR: injecting missing classes/jars..."
        $tmp = Join-Path $env:TEMP ([Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $tmp | Out-Null
        try {
            [System.IO.Compression.ZipFile]::ExtractToDirectory($WarSrc, $tmp)

            # ensure WEB-INF/classes path exists
            $classesTarget = Join-Path $tmp 'WEB-INF\classes\com\psicoatualcance\repository'
            if (-not (Test-Path $classesTarget)) { New-Item -ItemType Directory -Path $classesTarget -Force | Out-Null }

            # copy compiled classes from target if available
            $compiledSrc = Join-Path $ProjectDir 'target\classes\com\psicoatualcance\repository\CitaRepositoryMySQL.class'
                    if (-not (Test-Path $compiledSrc)) {
                Write-Warning "Compiled class not found at $compiledSrc — skipping class injection"
            } else {
                Copy-Item -Force $compiledSrc $classesTarget
                Write-Host "Inserted CitaRepositoryMySQL.class into WAR content"
            }

            # DO NOT inject the MySQL connector into the WAR. Use the connector from Tomcat's lib to avoid
            # classloader duplication which can prevent proper driver deregistration on undeploy.
            $tomcatLib = Join-Path $Catalina 'lib'
            $hasConnectorInTomcat = $false
            if (Test-Path $tomcatLib) {
                $tcJar = Get-ChildItem -Path $tomcatLib -Filter 'mysql-connector-j*.jar' -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($tcJar) { $hasConnectorInTomcat = $true; Write-Host "Found MySQL connector in Tomcat lib: $($tcJar.Name)" }
            }
            if (-not $hasConnectorInTomcat) {
                Write-Warning "MySQL connector not found in Tomcat lib. Will try to copy one from local m2 into Tomcat lib."
                $m2 = Join-Path $env:USERPROFILE '.m2\repository\com\mysql\mysql-connector-j'
                if (Test-Path $m2) {
                    $jar = Get-ChildItem -Path $m2 -Recurse -Include 'mysql-connector-j-*.jar' | Select-Object -First 1
                    if ($null -ne $jar) {
                        Copy-Item -Force $jar.FullName $tomcatLib
                        Write-Host "Copied $($jar.Name) into Tomcat lib: $tomcatLib"
                        $hasConnectorInTomcat = $true
                    } else {
                        Write-Warning "No mysql connector jar found in local m2. Will try maven to copy dependency but will not inject into WAR."
                        Push-Location $ProjectDir
                        & $MvnCmd dependency:copy-dependencies -DincludeArtifactIds=mysql-connector-j -DoutputDirectory=target\dependency-jars
                        Pop-Location
                        $depJar = Get-ChildItem -Path (Join-Path $ProjectDir 'target\dependency-jars') -Filter 'mysql-connector-j*.jar' -ErrorAction SilentlyContinue | Select-Object -First 1
                        if ($depJar) {
                            Copy-Item -Force $depJar.FullName $tomcatLib
                            Write-Host "Copied dependency jar $($depJar.Name) into Tomcat lib"
                            $hasConnectorInTomcat = $true
                        } else { Write-Warning "Failed to obtain mysql connector jar; the app may not connect to MySQL." }
                    }
                } else {
                    Write-Warning "Local m2 repo not found at $m2; cannot copy connector to Tomcat lib. Ensure mysql-connector is present in Tomcat lib."
                }
            }

            # re-create WAR
            $backup = $WarSrc + '.bak'
            Copy-Item -Force $WarSrc $backup
            Remove-Item -Force $WarSrc
            [System.IO.Compression.ZipFile]::CreateFromDirectory($tmp, $WarSrc)
            Write-Host "Repackaged WAR with injected artifacts. Backup left at $backup"
        } finally {
            Remove-Item -Recurse -Force $tmp
        }
    } else {
        Write-Host "WAR already contains repository class and connector jar. No injection needed."
    }

    # 2) Stop Tomcat
    Write-Host "Stopping Tomcat..."
    $catalinaStop = Join-Path $Catalina 'bin\catalina.bat'
    if (-not (Test-Path $catalinaStop)) { Write-Error "Cannot find catalina.bat at $catalinaStop"; exit 1 }
    $env:CATALINA_HOME = $Catalina
    $env:CATALINA_BASE = $Catalina
    & $catalinaStop stop
    Start-Sleep -Seconds 2

    # 3) Remove exploded app and old WAR for a clean deploy
    $exploded = Join-Path $Catalina 'webapps\java-jsp-tomcat-project-1.0-SNAPSHOT'
    if (Test-Path $exploded) {
        Write-Host "Removing exploded app: $exploded"
        Remove-Item -Recurse -Force $exploded
    }
    if (Test-Path $WarDst) {
        Write-Host "Removing old WAR: $WarDst"
        Remove-Item -Force $WarDst
    }

    # 4) Copy WAR
    Write-Host "Copying WAR to Tomcat webapps..."
    Copy-Item -Force $WarSrc $WarDst

    # 5) Start Tomcat
    Write-Host "Starting Tomcat..."
    $env:CATALINA_HOME = $Catalina
    $env:CATALINA_BASE = $Catalina
    & $catalinaStop start

    # 6) Wait for port 8080 to be available (timeout 60s)
    $timeout = 60; $i = 0
    while ($i -lt $timeout) {
        $i++
        $t = Test-NetConnection -ComputerName 'localhost' -Port 8080
        if ($t.TcpTestSucceeded) { Write-Host "Tomcat is listening on 8080"; break }
        Start-Sleep -Seconds 1
    }
    if ($i -ge $timeout) { Write-Error "Tomcat did not start listening on 8080 after $timeout seconds"; exit 1 }

    Start-Sleep -Seconds 2

    # 7) Optional: remove diagnostic files we earlier added (safe if they don't exist)
    $diag1 = Join-Path $Catalina 'webapps\java-jsp-tomcat-project-1.0-SNAPSHOT\testdb.jsp'
    $diag2 = Join-Path $Catalina 'webapps\java-jsp-tomcat-project-1.0-SNAPSHOT\testsave.jsp'
    if (Test-Path $diag1) { Remove-Item -Force $diag1; Write-Host "Removed $diag1" }
    if (Test-Path $diag2) { Remove-Item -Force $diag2; Write-Host "Removed $diag2" }

    # 8) POST a test appointment
    Write-Host "Posting test appointment to CitaServlet..."
    try {
        $resp = Invoke-WebRequest -Uri 'http://localhost:8080/java-jsp-tomcat-project-1.0-SNAPSHOT/CitaServlet' -Method Post -Body @{
            nombre='DeployTest'
            email='deploy@test'
            telefono='555'
            motivo='deploy test'
            fechaHora=(Get-Date).AddDays(1).ToString('yyyy-MM-ddTHH:mm:ss')
            psicologo='Dr Deploy'
        } -UseBasicParsing -SkipHttpErrorCheck
        Write-Host "POST returned status: $($resp.StatusCode)"
    } catch {
        Write-Warning "POST failed: $_"
    }

    # 9) Query MySQL inside container
    Write-Host "Querying MySQL (container: mysql-local) for last 10 citas..."
    $query = 'SELECT u.id AS uid, u.nombre, c.id AS cid, c.motivo, c.fecha_hora FROM psicoatualcance.usuario u JOIN psicoatualcance.cita c ON u.id=c.usuario_id ORDER BY c.id DESC LIMIT 10;'
    Write-Host "Running docker exec mysql-local mysql -uroot -proot -e <query>"
    $res = & docker exec mysql-local mysql -uroot -proot -e $query 2>&1
    Write-Host "MySQL result:`n$res"

    Write-Host "Done. If you see your DeployTest row in the MySQL result, persistence is working."

} catch {
    Write-Error "Error during deployment script: $_"
    exit 1
}
