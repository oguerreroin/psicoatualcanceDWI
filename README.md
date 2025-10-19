# Psicología a tu alcance — psicoatualcanceDWI

Pequeño resumen y guía rápida para desarrollar y desplegar el proyecto localmente.

## ¿Qué contiene este repo?
- `java-jsp-tomcat-project/` — aplicación Java web (JSP + Servlets) que maneja "agendar citas".
- `tools/` — scripts PowerShell para provisión, despliegue y pruebas locales.
- `.local/tomcat/` — Tomcat embebido usado para pruebas locales (no se debe commitear a un repositorio remoto normalmente).

## Requisitos mínimos
- Java JDK 21
- Apache Tomcat 9.x (local) — el conector MySQL (`mysql-connector-j-*.jar`) debe estar en `CATALINA_BASE/lib`.
- Maven (o usar mvnw si está presente)
- Docker (para ejecutar el contenedor MySQL `mysql-local` usado en scripts)

## Despliegue rápido (desde la raíz del repo)
1. Asegúrate de que Tomcat tenga `mysql-connector-j` en su carpeta `lib`.
2. Ejecuta el script de despliegue y prueba:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\deploy-and-test.ps1
```

El script compila, empaqueta el WAR, lo despliega en Tomcat, envía un POST de prueba y consulta MySQL para verificar persistencia.

## Notas y recomendaciones
- El `pom.xml` marca `mysql-connector-j` como `provided` para evitar duplicarlo en el WAR y evitar problemas de classloader.
- Si la app no persiste en MySQL, revisa `logs/catalina.*.log` y el archivo `WEB-INF/data/citas.txt` (fallback de almacenamiento).

## Documentación adicional
Más detalles sobre el script de herramientas están en `tools/README.md`.

---
Si quieres que lo adapte (por ejemplo, CI/CD, GitHub Actions, o un Dockerfile para Tomcat + MySQL), dime qué prefieres y lo agrego.