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

**Un informe válido por commit.** Si el PR ya tiene un informe válido de la
misma base y la misma cabeza, editar el título, reabrirlo o marcarlo listo no
repite la revisión ni consume la API: el resumen de Actions dice «no
repetida». Antes, abrir un borrador y marcarlo listo dejaba dos informes
distintos del mismo commit. «Re-run jobs» siempre revisa. Un informe inválido
o un fallo de API no cuentan como revisión hecha. Solo se reconoce la marca al
principio de un comentario de GitHub Actions, y si no se puede leer el
historial se revisa igualmente.

**Cómo se lee el informe.** Tras el resumen va la línea **Resultado**
(hallazgos, comprobaciones pendientes y sin defecto aparente). Después los
hallazgos, luego las comprobaciones **pendientes** —lo que el modelo no pudo
decidir y conviene mirar a mano— y, plegadas, las que no encontraron defecto.

**Modelos que razonan.** `mistral-large-latest` pasó a razonar antes de
responder: devuelve el contenido en bloques (`thinking` y `text`) y gastaba el
margen de salida entero en razonar, de ahí los informes «no completada»
(medido en `email-triage-plugin#202`: 31.129 caracteres de razonamiento y
ninguno de respuesta con 8.000 tokens). El revisor lee solo los bloques `text`,
envía `reasoning_effort: "low"` —si el modelo no admite el parámetro, lo retira
y repite— y da un margen de 16.000 tokens. Si la API corta la respuesta, el
informe añade su código de causa (`length`) y el registro de Actions dice el
modelo servido y cuánto ocupó el razonamiento y cuánto la respuesta: solo
recuentos, nada del contenido. Cada revisión consume así del orden de 10.000
tokens de salida; para evitarlo, fija un modelo sin razonamiento en
`MISTRAL_MODEL`. Que 16.000 basten para diffs mucho mayores **no está medido**.

El modelo debe dar escenarios, comprobaciones pendientes y citas del diff.
Las citas se validan literalmente, salvo la sangría y los espacios de los
extremos, que no cuentan (el modelo suele citar sin sangría, y exigirla
invalidaba la revisión entera); el resto debe coincidir carácter a carácter y
una cita sin letras ni números no vale. Las comprobaciones de rutas admiten
renombrados, permisos y binarios sin hunks. Si la respuesta llega pero no
valida, se pide una segunda vez; un fallo de API no se repite por esta vía. El
registro de Actions y el comentario nombran la regla incumplida, nunca el
contenido de la respuesta. Dos respuestas inválidas o un fallo de API hacen
fallar el check, pero no demuestran un defecto del código. El resumen de
Actions se escribe antes de publicar para conservarlo si falla GitHub.

Se envían hasta 150.000 caracteres de diff y 20.000 de guía. Como contexto van
**las funciones completas de la versión nueva que contienen las líneas
cambiadas**, de archivos Python y shell, con sus números de línea: hasta 10.000
caracteres por archivo y 40.000 en conjunto, primero el código y después los
tests, cortando por líneas enteras. Antes se enviaba el principio de cada
archivo Python y nada de `recon.sh`. En shell las funciones se reconocen por
líneas (`nombre() {` … `}` en la columna 0, anidadas incluidas), sin ejecutar
nada; un cambio fuera de toda función, o dentro de una de más de 200 líneas
como `main`, lleva una ventana de 15 líneas. Los recortes se indican. Las
asignaciones reconocidas por el patrón de claves de `mask_secrets` de `recon.sh`
se filtran antes de enviar y publicar; en CI se sustituye el valor completo por
`***`. No es detección universal de secretos: credenciales sin una asignación
reconocible requieren revisión humana. La clave de API solo viaja como cabecera
de autenticación y los cuerpos de errores HTTP no se publican.

El token tiene `contents: read` y `pull-requests: write`. El código del PR no se
ejecuta con la clave. El job de tests carece de esa clave. El revisor vive fuera
de `plugin/` y no cambia lo que el producto instalado lee, escribe o envía.

El prompt pide que cada comprobación intente romper el cambio con una entrada
que los tests del diff no ejerciten, y que cada hallazgo sobreviva a un intento
de refutación o pase a «pendiente». Que eso mejore el juicio del modelo **no
está medido**.

Los tests locales simulan la API y GitHub. Validan transporte, formato, citas,
filtrado, contexto e historial; no la calidad del juicio de Mistral. Una cita válida no
demuestra un defecto, y «sin hallazgos» no demuestra corrección.
