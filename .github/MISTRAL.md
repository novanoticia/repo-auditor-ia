# Revisión de PR con Mistral

El workflow `Mistral PR Review` (`.github/workflows/mistral-review.yml`) solo
**llama** al revisor compartido
[novanoticia/mistral-review](https://github.com/novanoticia/mistral-review),
que lee el diff y las reglas de `REVIEW.md`, `AGENTS.md` o `CLAUDE.md`, por ese
orden. Mistral analiza y comenta; Claude y el mantenedor se encargan de las
reparaciones. No modifica código, crea commits ni fusiona cambios. No sustituye
al protocolo ni a las plantillas del plugin.

Desde el 2026-11-15 el código, las pruebas y la documentación detallada del
revisor viven en ese repo; antes había aquí una copia propia en
`.github/scripts/`, con sus tests en `tests/test_mistral_*.py` y un job
`mistral-tests` en `ci.yml`. Lo que aportaba este repo —contexto de funciones
de shell (`recon.sh`) y el filtro de asignaciones sensibles de `mask_secrets`—
se fusionó en el revisor compartido, así que llega a todos los repos.

## Activación

En Settings → Secrets and variables → Actions:

1. Secreto `MISTRAL_API_KEY` con la clave de Mistral.
2. Opcional: variable `MISTRAL_MODEL`; sin ella se usa el modelo por defecto
   del revisor compartido (`zai-glm-5-3-flash`).

Si no hay clave o el PR viene de un fork, se informa de revisión omitida: no
cuenta como evaluación sin hallazgos. El check se llama
`mistral-review / mistral-review`.

## Lo propio de este repo

No se excluye ningún archivo. El token tiene `contents: read` y
`pull-requests: write`; el código del PR no se ejecuta con la clave. El revisor
vive fuera de `plugin/` y no cambia lo que el producto instalado lee, escribe o
envía.

## Contraste de revisiones de otras IAs

El workflow `Mistral Reply to AI Reviews` (`.github/workflows/mistral-reply.yml`)
llama a `reply.yml` del mismo revisor compartido. Cuando otra IA (Codex, Claude,
Copilot, CodeRabbit o Gemini) deja hallazgos en un PR, Mistral contrasta cada uno
leyendo el código y responde con un dictamen: de acuerdo, no se sostiene, ya
corregido o pendiente, con citas literales. Solo comenta: no aplica parches.
Además del código, envía a Mistral el texto de esos hallazgos.

Usa el mismo secreto y las mismas variables que la revisión. La variable
opcional `MISTRAL_REPLY_MODEL` elige otro modelo de Mistral solo para el
contraste. Tampoco excluye ningún archivo. También se puede lanzar a mano: **Actions → Mistral Reply to
AI Reviews → Run workflow**, con el número del PR y el id del comentario.

Los dos workflows están fijados en la misma versión del revisor: `@` de `uses:`
y `ref:` deben coincidir en ambos archivos. El dictamen es otra opinión
automatizada; compruébalo antes de actuar.

## Evaluación del revisor

El workflow `Mistral Eval` (`.github/workflows/mistral-eval.yml`) mide si el
revisor encuentra defectos reales de este repo. No se lanza solo: **Actions →
Mistral Eval → Run workflow**. Cada ejecución hace una petición de pago por
caso y repetición (del orden de medio céntimo cada una).

Los casos están en `.github/eval/casos.json`:

- `c1-grep-status-invertido`, **control**: `grep_status` con la guarda
  invertida, un defecto evidente puesto a propósito y deshecho en el commit
  siguiente. Un revisor que no lo vea no ve defectos evidentes.
- `p33-openrouter-toma-mistral-model`: el hallazgo de Codex del #33, corregido
  en `12d75b2`.
- `p22-recon-manual-sin-camelcase`: el hallazgo de Codex del #22, corregido en
  `22970f8`. La línea de `KEYVAL_REGEX` que hace falta para verlo entero no
  está en el diff: es un caso difícil a propósito.

Como este repo no tiene Python, cada caso lleva `archivos_objetivo`
(disponible desde mistral-review v1.5). Los casos citan SHA de commits
concretos: un PR que los cambie hay que fusionarlo con *merge commit*, nunca
con *squash* ni *rebase*. Método y cómo leer el resultado:
[evaluación](https://github.com/novanoticia/mistral-review/blob/main/docs/evaluacion.md).

## Límites

El filtro de secretos no es detección universal: credenciales sin una
asignación reconocible requieren revisión humana. Una cita válida no demuestra
un defecto, y «sin hallazgos» no demuestra corrección.
