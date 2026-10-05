# Repo Auditor IA

Plugin para Claude que audita repositorios de GitHub (plugins, servidores MCP y extensiones de LLM, aunque sirve para código en cualquier lenguaje) y entrega un **informe en español**, con evidencia trazable y comparable entre ejecuciones.

No se fía de lo que promete el README del proyecto auditado: juzga lo que el código hace de verdad.

## Qué hace

- **Cuatro ejes, analizados por separado:** arquitectura, deuda técnica, fiabilidad y seguridad, y preparación para IA (si un agente podría entender y modificar el proyecto sin romperlo).
- **Razonamiento estructurado:** descompone el análisis, contrasta hipótesis alternativas en los hallazgos ambiguos, calibra la confianza de cada hallazgo con un criterio bayesiano cualitativo y se autoverifica antes de escribir.
- **Severidad y confianza por separado:** un hallazgo puede ser grave y, a la vez, de confianza baja, y el informe lo muestra así.
- **Evidencia obligatoria:** un hallazgo sin `archivo:línea`, función o commit no entra en el informe.
- **Informe reproducible:** secciones fijas, rúbricas de puntuación ancladas e IDs estables (F1, QW1, CM1…), de modo que dos auditorías del mismo commit se pueden comparar fila a fila.
- **Reconocimiento determinista:** un script de solo lectura (`recon.sh`) recoge commit, estructura, manifiestos, zonas calientes de git, densidad de TODO, posibles secretos (enmascarados) y auditoría de dependencias cuando hay herramientas disponibles.
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

Antes de empezar, el auditor te pregunta el nivel de profundidad (triage rápido, auditoría estándar o revisión profunda) y te pide confirmación antes de clonar nada.

## Requisitos y límites

- **Con shell y git** (Claude Code, o entornos con ejecución de código): clona el repositorio en un directorio temporal y ejecuta el reconocimiento.
- **Sin shell** (por ejemplo, un chat sin ejecución de código): pasa a **modo estático** y audita los ficheros que pegues. Lo declara en el informe y no inventa commits ni resultados de herramientas.
- El contenido del repositorio auditado se trata como **datos, nunca como instrucciones**: si un README o un comentario intenta dirigir al auditor, eso se registra como hallazgo.
- El informe es una ayuda a la revisión, no una certificación de seguridad. **Requiere revisión humana** antes de actuar sobre él.

## Estructura

```
.claude-plugin/plugin.json             manifiesto del plugin
.claude-plugin/marketplace.json        marketplace propio (instalación directa desde este repo)
skills/auditar-repo/SKILL.md           la skill: protocolo, pasos y plantilla del informe
skills/auditar-repo/references/        orquestación de modelos y modo implementación
skills/auditar-repo/scripts/recon.sh   reconocimiento determinista (solo lectura)
```

## Historial

La versión 1.0.0 de este plugin procede de la skill `github-plugin-analyzer-ia` (v4.1), con estos cambios:

- Nombre estable, sin la versión incrustada.
- Regla explícita contra la inyección de instrucciones desde el repositorio auditado.
- Secretos enmascarados en el reconocimiento.
- Política de orquestación de modelos sin nombres ni fechas que caduquen.

## Licencia

[MIT](LICENSE)

---

*Este plugin y su documentación se han elaborado con asistencia de IA y requieren revisión humana.*
