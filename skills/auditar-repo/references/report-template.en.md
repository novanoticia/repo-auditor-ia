# Report template — English (`--lang en`)

Loaded by **Step 8** when the report language is English. Follow the template **exactly**;
the language-neutral rules (section order, IDs, sorting, score anchors) live in `SKILL.md`.

## Labels

| Element | Value |
|---|---|
| Verdicts | Solid · Functional but fragile · Deceptively functional · Needs serious work |
| Confidence (Rule 5) | High · Medium · Low |
| Static mode | Commit `n/a — static mode` · scores `(estimated, not executed)` |
| Mandatory creative item | Non-Obvious Recommendation |
| Clone confirmation (Step 2) | "I'm going to clone `<REPO_URL>` into a temporary directory to audit its code. Shall we proceed?" |
| Next steps (Step 9) | Go deeper · Run a fix · Issue template · AI-readiness · Comparison · Cleanup |
| Engine wording (Model-Naming) | "the internal reasoning protocol", "the auditor" |

## Template

```markdown
<veredicto>
# 🔍 Audit: <repo-name>

**Verdict:** <Solid | Functional but fragile | Deceptively functional | Needs serious work>
<2–3 honest sentences that follow from the prioritized list, not from optimism>

**Quality: X/10** · **AI-Readiness: X/10** · Commit: `<hash | "n/a — static mode">` · Stack: <runtime> · Maturity: <prototype/beta/prod>
</veredicto>

<modelo_superior>
## Could more capable reasoning improve this code?
<What could be refactored safely vs. what needs a human design decision.
"More capable" = abstract analytical capability, never a specific AI product.>
</modelo_superior>

<diagnostico>
## Executive Diagnosis
- **Repository:** <URL or "N/A — local file / static mode">
- **Actual purpose:** <what it does vs. what it claims>
- **Size and test coverage:** <assessment>
</diagnostico>

<hallazgos>
## Prioritized Findings
Fixed order: first by severity (🔴→🔵), then, at equal severity, by confidence (High→Low).
Assign stable IDs after sorting (F1, F2, …): Step 10 refers to them.

| ID | Sev | Conf | Finding | Evidence | Impact |
|----|-----|------|---------|----------|--------|
| F1 | 🔴  | High | …       | `file:line` | … |
</hallazgos>

<epistemico>
## Epistemic Audit and Hidden Risks
<Happy-path bias, concurrency, invisible fragility — with exact file:line>
<Open hypotheses (R2): interpretation + the test that would confirm or rule it out>
</epistemico>

<recomendaciones>
## Recommendations (max. 7, by real impact)
### ⚡ Quick Wins (high value / low effort)
1. **QW1 · <Problem>** → <Concrete fix> → `file:line` → resolves <F#>
### 🏗️ Major Surgery (structural refactors)
1. **CM1 · <Problem>** → <Concrete fix> → `file/module` → resolves <F#>
### 💡 Non-Obvious Recommendation (mandatory)
<The creative lever from Step 6: alternative approach / reframe / AI-readiness + why>
</recomendaciones>

<contexto>
## Context and Evolution
- **Version history / diff between versions:** hotspots, what improved, what regressed.
- **Stack and dependencies:** notable versions and risks.
</contexto>

<limites>
## Limits of the Analysis
<What was verified, what wasn't, which areas were sampled, pending hypotheses, declared
priors/assumptions, R1 axes with partial coverage. If work was delegated (Step 3.5), state
which axes/paths were delegated and the **model-usage log** (which stretch ran on which
model and why: value / block / redirect / quota). In static mode, state which dynamic steps
were left out.>
</limites>

<nota_etica>
---
*Report prepared with AI assistance. Requires human review before acting on its
conclusions.*
</nota_etica>
```

## Golden example (shape only — do not copy its content)

```markdown
<veredicto>
# 🔍 Audit: acme-mcp-server
**Verdict:** Functional but fragile
It starts and responds, but it mixes external input with internal instructions and has no
rate limiting. Solid in structure, fragile at its trust boundaries.
**Quality: 6/10** · **AI-Readiness: 5/10** · Commit: `a1b2c3d` · Stack: Node 20 · Maturity: beta
</veredicto>
... (intermediate sections) ...
<hallazgos>
| ID | Sev | Conf | Finding | Evidence | Impact |
|----|-----|------|---------|----------|--------|
| F1 | 🔴 | High | Prompt injection: user input concatenated into the system prompt | `src/handler.ts:42` | Hostile input redirects the agent |
</hallazgos>
```
