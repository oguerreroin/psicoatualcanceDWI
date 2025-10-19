# Instrucciones de despliegue y pruebas (tools)

Este archivo describe cómo usar las utilidades dentro de `tools/` para desplegar y verificar la aplicación `java-jsp-tomcat-project` localmente.

## Requisitos previos
- Java JDK 21 instalado y disponible.
- Apache Tomcat (probado con Tomcat 9.0.x). El archivo `mysql-connector-j` debe residir en `CATALINA_BASE/lib` (o `CATALINA_HOME/lib`).
- Maven instalado (o `mvnw` presente en el proyecto).
- Docker (para ejecutar un contenedor MySQL). El proyecto asume un contenedor llamado `mysql-local` con la base de datos `psicoatualcance` configurada.

## Qué hace `deploy-and-test.ps1`
1. Compila el proyecto con Maven (`mvn -U -DskipTests clean package`).
2. Verifica el contenido del WAR y, si faltan clases de repositorio, las inyecta desde `target/classes`.
3. NO inyecta el conector MySQL en el WAR. En su lugar, se asegura de que el conector esté presente en `CATALINA_BASE/lib`; si no lo encuentra, intenta copiarlo desde el repositorio local de Maven (`%USERPROFILE%\.m2`).
4. Reinicia Tomcat (stop/start), despliega el WAR y espera a que el puerto 8080 esté disponible.
5. Envía un POST de prueba a `CitaServlet` y consulta MySQL dentro del contenedor `mysql-local` para verificar persistencia.

## Uso (PowerShell / pwsh)
Abrir PowerShell en la raíz del repo y ejecutar:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\deploy-and-test.ps1
```

Si Maven no está en `PATH`, asegúrate de exportar su `bin` en `PATH` antes de ejecutar:

```powershell
$env:PATH = "C:\\Program Files\\Apache\\apache-maven-3.9.11\\bin;" + $env:PATH
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\deploy-and-test.ps1
```

## Notas importantes
- El conector MySQL (`mysql-connector-j-*.jar`) debe estar en `CATALINA_BASE/lib`. El script intentará copiarlo desde `%USERPROFILE%\.m2` si no está presente.
- El `pom.xml` del proyecto marca `mysql-connector-j` como `provided` para evitar que el WAR lo empaquete (evita problemas de classloader y evita warnings de Tomcat sobre drivers que no se pueden deregistrar).
- El listener `com.psicoatualcance.listener.DbCleanupListener` está registrado para cerrar y deregistrar el driver MySQL al detener la aplicación, previniendo fugas de memoria en Tomcat.

## Limpieza
- El script puede dejar un backup del WAR en `target/*.war.bak`. Puedes eliminarlo si lo deseas.

## Problemas comunes
- Si ves filas guardadas en `WEB-INF/data/citas.txt`, significa que la persistencia MySQL falló y la aplicación usó el fallback. Revisa `logs/catalina.*.log` para ver el stacktrace.

## Contacto
Si quieres que adapte el script para otros entornos o lo integre con CI/CD, dime qué sistema de CI usas y lo preparo.
