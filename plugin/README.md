# Repo Auditor IA

Plugin para Claude que audita repositorios de GitHub (plugins, servidores MCP y extensiones de LLM, aunque sirve para código en cualquier lenguaje) y entrega un **informe en español, inglés o francés**, con evidencia trazable y comparable entre ejecuciones.

[Privacy / Privacidad](#datos-y-red): el plugin no tiene servidor propio ni recoge datos; qué lee, escribe y envía está detallado en «Datos y red».

## Uso

Invoca la skill con una URL de GitHub o una ruta local, por ejemplo `/repo-auditor-ia:auditar-repo https://github.com/usuario/proyecto --lang es` (también `--lang en` y `--lang fr`). El auditor te pregunta el nivel de profundidad y te pide confirmación antes de clonar nada.

El informe es una ayuda a la revisión, no una certificación de seguridad. **Requiere revisión humana** antes de actuar sobre él.

## Datos y red

Qué lee, qué escribe y qué sale de tu máquina:

- **Sin servidor propio.** El plugin no tiene servidor, servicio de terceros ni servidores MCP: el autor no recibe ni retiene ningún dato.
- **Lee** el repositorio que le pidas auditar (código, manifiestos e historial de git). Puede contener datos personales incidentales, como nombres en comentarios o autores de commits. Los trata solo durante la sesión y el informe cita ubicaciones y tipos, nunca valores de secretos.
- **Escribe** únicamente en un directorio temporal del sistema (el clon de trabajo y la salida del reconocimiento), que borra al terminar. No modifica el repositorio auditado salvo que actives el modo de implementación y lo confirmes.
- **Red.** Para una URL remota, el auditor clona el repositorio (descarga, no envía) tras pedirte confirmación. Además, si están instalados y el repo tiene lockfile o manifiesto compatible, el reconocimiento ejecuta las herramientas de auditoría de dependencias (`npm audit`, `pip-audit`, `cargo audit`). Esas herramientas consultan sus propias bases de vulnerabilidades y pueden enviar a su registro los nombres y versiones de las dependencias del repo. Si no están instaladas, el reconocimiento lo declara como omitido y no consulta nada.
- **Tu asistente.** El contenido analizado pasa por el asistente de IA con el que uses el plugin y se rige por las condiciones de ese servicio.

## Más información

Documentación completa, historial de versiones y código fuente: <https://github.com/novanoticia/repo-auditor-ia>. Licencia MIT.
