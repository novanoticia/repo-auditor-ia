# Revisión de PR con Mistral

El workflow `Mistral PR Review` revisa cambios con la API de
[Mistral AI](https://github.com/mistralai). Lee las reglas de `REVIEW.md`,
`AGENTS.md` o `CLAUDE.md`, por ese orden. Mistral analiza y comenta; Claude y
el mantenedor se encargan de las reparaciones. No modifica código, crea commits
ni fusiona cambios. No sustituye al protocolo ni a las plantillas del plugin.

## Activación

Fusiona la instalación y comprueba en Settings → Secrets and variables → Actions
que exista el secreto `MISTRAL_API_KEY`. La variable opcional `MISTRAL_MODEL`
selecciona el modelo; el valor predeterminado es `mistral-large-latest`.
La integración no tiene permiso para consultar secretos ni variables de Actions,
por lo que su existencia no está confirmada. No se copian claves de otros repos.

El script se ejecuta desde la rama predeterminada y solo lee objetos Git del
PR. Durante el PR de instalación se omite la llamada si el script todavía no
existe en esa rama. Los tests del revisor sí corren en otro job, sin la clave.
Si no hay clave o el PR viene de un fork, se informa de revisión omitida: no
cuenta como evaluación sin hallazgos.

## Resultados

Se revisa al abrir, actualizar, editar, reabrir o marcar listo un PR. Cada
resultado crea un comentario nuevo con SHA, modelo y enlace al intento de
Actions. No sobrescribe los anteriores. Un push cancela la revisión anterior
en curso; si se cancela antes de publicar, puede no quedar comentario.

El modelo debe dar escenarios, comprobaciones pendientes y citas del diff.
Las citas se validan literalmente; las comprobaciones de rutas admiten
renombrados, permisos y binarios sin hunks. Una respuesta inválida o fallo de API
hace fallar el check, pero no demuestra un defecto del código. El resumen de
Actions se escribe antes de publicar para conservarlo si falla GitHub.

Se envían hasta 150.000 caracteres de diff, 20.000 de guía y 10.000 por archivo
de contexto Python, con 40.000 en conjunto. Los recortes se indican. Las
asignaciones reconocidas por el patrón de claves de `mask_secrets` de `recon.sh`
se filtran antes de enviar y publicar; en CI se sustituye el valor completo por
`***`. No es detección universal de secretos: credenciales sin una asignación
reconocible requieren revisión humana. La clave de API solo viaja como cabecera
de autenticación y los cuerpos de errores HTTP no se publican.

El token tiene `contents: read` y `pull-requests: write`. El código del PR no se
ejecuta con la clave. El job de tests carece de esa clave. El revisor vive fuera
de `plugin/` y no cambia lo que el producto instalado lee, escribe o envía.

Los tests locales simulan la API y GitHub. Validan transporte, formato, citas,
filtrado e historial; no la calidad del juicio de Mistral. Una cita válida no
demuestra un defecto, y «sin hallazgos» no demuestra corrección.
