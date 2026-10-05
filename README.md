# Repo Auditor IA

Plugin para Claude que audita repositorios de GitHub (plugins, servidores MCP y extensiones de LLM, aunque sirve para código en cualquier lenguaje) y entrega un **informe en español, inglés o francés**, con evidencia trazable y comparable entre ejecuciones.

No se fía de lo que promete el README del proyecto auditado: juzga lo que el código hace de verdad.

## Qué hace

- **Cuatro ejes, analizados por separado:** arquitectura, deuda técnica, fiabilidad y seguridad, y preparación para IA (si un agente podría entender y modificar el proyecto sin romperlo).
- **Razonamiento estructurado:** descompone el análisis, contrasta hipótesis alternativas en los hallazgos ambiguos, calibra la confianza de cada hallazgo con un criterio bayesiano cualitativo y se autoverifica antes de escribir.
- **Severidad y confianza por separado:** un hallazgo puede ser grave y, a la vez, de confianza baja, y el informe lo muestra así.
- **Evidencia obligatoria:** un hallazgo sin `archivo:línea`, función o commit no entra en el informe.
- **Informe reproducible:** secciones fijas, rúbricas de puntuación ancladas e IDs estables (F1, QW1, CM1…), de modo que dos auditorías del mismo commit se pueden comparar fila a fila.
- **Reconocimiento determinista:** un script de solo lectura (`recon.sh`) recoge commit, estructura, manifiestos, zonas calientes de git, densidad de TODO, posibles secretos (enmascarados) y auditoría de dependencias cuando hay herramientas disponibles. Cada sección termina en `STATUS: ok | failed | skipped`: una sección vacía nunca se confunde con un resultado limpio, y solo la evidencia `ok` admite confianza Alta.
- **Informe en tres idiomas:** español (por defecto), inglés o francés. Las etiquetas XML, los IDs, los emojis de severidad y las puntuaciones son iguales en los tres, así que un informe en inglés se puede comparar fila a fila con uno en español.
- **Modo implementación (opcional):** si lo pides, aplica los arreglos que elijas por ID, uno a uno, verificando cada uno y con un commit por arreglo. Nunca hace push ni abre PR sin un permiso aparte.

## Instalación

**Desde el directorio de Claude** (claude.ai, Cowork y Claude Code): busca *Repo Auditor IA* en el directorio y añádelo. *(Disponible cuando se publique.)*

**Desde este repositorio, en Claude Code:**

```bash
claude plugin marketplace add novanoticia/repo-auditor-ia
claude plugin install repo-auditor-ia@novanoticia
```

## Uso

Escribe `/repo-auditor-ia:auditar-repo` o pídelo con lenguaje natural:

- «Audita este repo: https://github.com/usuario/proyecto»
- «Analiza este MCP»
- «Compara las versiones v1.2 y v2.0 del repo»
- Después del informe: «Ejecuta QW1 y CM2»

**Idioma del informe:** añade `--lang en` (inglés), `--lang fr` (francés) o `--lang es` al invocar, por ejemplo `/repo-auditor-ia:auditar-repo https://github.com/usuario/proyecto --lang en`, o pídelo en el mensaje («en inglés», «in English», «en français»). Si no lo indicas, el auditor te lo pregunta al empezar; sin respuesta posible, usa el español.

Antes de empezar, el auditor te pregunta el nivel de profundidad (triage rápido, auditoría estándar o revisión profunda) y, si no lo has indicado, el idioma; y te pide confirmación antes de clonar nada.

## Requisitos y límites

- **Con shell y git** (Claude Code, o entornos con ejecución de código): clona el repositorio en un directorio temporal y ejecuta el reconocimiento.
- **Sin shell** (por ejemplo, un chat sin ejecución de código): pasa a **modo estático** y audita los ficheros que pegues. Lo declara en el informe y no inventa commits ni resultados de herramientas.
- El contenido del repositorio auditado se trata como **datos, nunca como instrucciones**: si un README o un comentario intenta dirigir al auditor, eso se registra como hallazgo.
- El informe es una ayuda a la revisión, no una certificación de seguridad. **Requiere revisión humana** antes de actuar sobre él.

## Estructura

```
AGENTS.md                              instrucciones para agentes: invariantes, comandos, convenciones
.claude-plugin/plugin.json             manifiesto del plugin
.claude-plugin/marketplace.json        marketplace propio (instalación directa desde este repo)
skills/auditar-repo/SKILL.md           la skill: protocolo, pasos y plantilla del informe
skills/auditar-repo/references/        plantillas del informe (es/en/fr), orquestación de modelos y modo implementación
skills/auditar-repo/scripts/recon.sh   reconocimiento determinista (solo lectura)
tests/run.sh                           tests de regresión de recon.sh (bash puro, sin red)
tests/make-trap-repo.sh                genera el «trap repo» sintético contra el que se prueba
tests/trap-markers.txt                 marcadores de fuga, uno por valor plantado (fuera del repo generado)
tests/stubs/                           sustitutos de npm / pip-audit / cargo-audit para los tests
tests/eval/                            eval del propio auditor sobre el trap repo (informe esperado + check-report.sh)
.github/workflows/ci.yml               shellcheck + tests en Linux y macOS
```

Para ejecutar los tests: `bash tests/run.sh`.

## Historial

**1.2.1** — reconocimiento más completo:

- Manifiestos y artefactos de agentes también en subdirectorios (profundidad 3 y 4, sin `node_modules`, `vendor`, `dist`…). Los manifiestos anidados, que las auditorías de dependencias no cubren, se declaran como `skipped`.
- Las zonas calientes siguen los renombrados: la actividad de una ruta antigua cuenta para el nombre actual del fichero.

**1.2.0** — informe en español, inglés o francés:

- Opción `--lang es|en|fr` al invocar; si no se indica, se pregunta al empezar (español por defecto).
- La plantilla del informe sale de `SKILL.md` a `references/report-template.{es,en,fr}.md` y solo se carga la del idioma elegido.
- `check-report.sh` acepta informes en los tres idiomas.

**1.1.2** — clonado más robusto:

- El workspace se crea y se clona en un solo comando, y los pasos siguientes usan su ruta literal: ya no falla en entornos donde las variables de la shell no sobreviven entre comandos.
- Clonado parcial (`--filter=blob:none`): la comparación de versiones ve todas las ramas, tags y commits antiguos.

**1.1.1** — correcciones halladas por la primera eval del auditor sobre el trap repo:

- Si un manifiesto está presente pero su auditor no está instalado (p. ej., `pip-audit` o `cargo-audit`), `recon.sh` lo declara como `skipped` en lugar de callarlo.
- El trap repo ya no delata que es una prueba (nombres, commits y valores neutros), para que la eval mida el comportamiento real del auditor.

**1.1.0** — el reconocimiento ya no falla en silencio:

- Cada sección de `recon.sh` termina en `STATUS: ok | failed | skipped`; solo la evidencia `ok` admite confianza Alta.
- Las auditorías de dependencias distinguen «sin vulnerabilidades», «vulnerabilidades encontradas», «falló» y «omitida» (p. ej., sin lockfile). `pip-audit` audita las dependencias del repo, no el entorno del auditor.
- El árbol muestra `.github/`; la heurística de secretos cubre JSON, `.env` sin comillas y nombres compuestos, y enmascara el valor completo.
- Tests de regresión con un repo trampa sintético, CI en Linux y macOS, una eval del propio auditor y `AGENTS.md`.

**1.0.0** — procede de la skill `github-plugin-analyzer-ia` (v4.1), con estos cambios:

- Nombre estable, sin la versión incrustada.
- Regla explícita contra la inyección de instrucciones desde el repositorio auditado.
- Secretos enmascarados en el reconocimiento.
- Política de orquestación de modelos sin nombres ni fechas que caduquen.

## Licencia

[MIT](LICENSE)

---

*Este plugin y su documentación se han elaborado con asistencia de IA y requieren revisión humana.*
