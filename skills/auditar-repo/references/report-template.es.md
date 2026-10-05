# Report template — Español (`--lang es`, default)

Loaded by **Step 8** when the report language is Spanish. Follow the template **exactly**;
the language-neutral rules (section order, IDs, sorting, score anchors) live in `SKILL.md`.

## Labels

| Element | Value |
|---|---|
| Verdicts | Sólido · Funcional pero frágil · Engañosamente funcional · Necesita trabajo serio |
| Confidence (Rule 5) | Alta · Media · Baja |
| Static mode | Commit `n/a — modo estático` · scores `(estimado, sin ejecución)` |
| Mandatory creative item | Recomendación No Obvia |
| Clone confirmation (Step 2) | «Voy a clonar `<REPO_URL>` en un directorio temporal para auditar su código. ¿Procedemos?» |
| Next steps (Step 9) | Profundizar · Ejecutar fix · Issue template · AI-readiness · Comparación · Limpieza |
| Engine wording (Model-Naming) | «el protocolo de razonamiento interno», «el auditor» |

## Template

```markdown
<veredicto>
# 🔍 Auditoría: <nombre-del-repo>

**Veredicto:** <Sólido | Funcional pero frágil | Engañosamente funcional | Necesita trabajo serio>
<2-3 frases honestas que se sigan de la lista priorizada, no del optimismo>

**Calidad: X/10** · **AI-Readiness: X/10** · Commit: `<hash | "n/a — modo estático">` · Stack: <runtime> · Madurez: <prototipo/beta/prod>
</veredicto>

<modelo_superior>
## ¿Podría un razonamiento más capaz mejorar este código?
<Qué refactorizaría con seguridad vs. qué requiere decisión humana de diseño.
"Más capaz" = capacidad analítica abstracta, nunca un producto de IA concreto.>
</modelo_superior>

<diagnostico>
## Diagnóstico Ejecutivo
- **Repositorio:** <URL o "N/A — fichero local / modo estático">
- **Propósito real:** <qué hace vs. lo que declara>
- **Tamaño y cobertura de tests:** <evaluación>
</diagnostico>

<hallazgos>
## Hallazgos priorizados
Orden fijo: primero por severidad (🔴→🔵), y a igual severidad por confianza (Alta→Baja).
Asigna IDs estables tras ordenar (F1, F2, …): son las referencias que usa el Step 10.

| ID | Sev | Conf | Hallazgo | Evidencia | Impacto |
|----|-----|------|----------|-----------|---------|
| F1 | 🔴  | Alta | …        | `file:línea` | … |
</hallazgos>

<epistemico>
## Auditoría Epistémica y Riesgos Ocultos
<Happy Path Bias, concurrencia, fragilidad invisible — con archivo:línea exactos>
<Hipótesis abiertas (R2): interpretación + prueba que la confirmaría o descartaría>
</epistemico>

<recomendaciones>
## Recomendaciones (máx. 7, por impacto real)
### ⚡ Quick Wins (alto valor / bajo esfuerzo)
1. **QW1 · <Problema>** → <Solución concreta> → `archivo:línea` → resuelve <F#>
### 🏗️ Cirugía Mayor (refactors estructurales)
1. **CM1 · <Problema>** → <Solución concreta> → `archivo/módulo` → resuelve <F#>
### 💡 Recomendación No Obvia (obligatoria)
<La palanca creativa del Step 6: enfoque alternativo / reframe / AI-readiness + porqué>
</recomendaciones>

<contexto>
## Contexto y Evolución
- **Historial de versiones / diff entre versiones:** zonas calientes, qué mejoró, qué regresó.
- **Stack y dependencias:** versiones y riesgos notables.
</contexto>

<limites>
## Límites del análisis
<Qué se verificó, qué no, qué áreas se muestrearon, hipótesis pendientes, priors/supuestos
declarados, ejes R1 con cobertura parcial. Si hubo delegación (Step 3.5), declara qué ejes/rutas
se delegaron y el **model-usage log** (qué tramo corrió en qué modelo y por qué: valor /
bloqueo / redirección / cuota). En modo estático, declara qué pasos dinámicos quedaron fuera.>
</limites>

<nota_etica>
---
*Informe elaborado con asistencia de IA. Requiere revisión humana antes de actuar sobre
sus conclusiones.*
</nota_etica>
```

## Ejemplo-oro (shape only — do not copy its content)

```markdown
<veredicto>
# 🔍 Auditoría: acme-mcp-server
**Veredicto:** Funcional pero frágil
Arranca y responde, pero mezcla entrada externa con instrucciones internas y no controla el
rate limit. Sólido en estructura, frágil en fronteras de confianza.
**Calidad: 6/10** · **AI-Readiness: 5/10** · Commit: `a1b2c3d` · Stack: Node 20 · Madurez: beta
</veredicto>
... (secciones intermedias) ...
<hallazgos>
| ID | Sev | Conf | Hallazgo | Evidencia | Impacto |
|----|-----|------|----------|-----------|---------|
| F1 | 🔴 | Alta | Inyección de prompt: input de usuario concatenado al system prompt | `src/handler.ts:42` | Un input hostil redirige al agente |
</hallazgos>
```
