# Implementation Mode — Step 10 reference

Read this file when the user explicitly asks to apply audit fixes ("ejecuta los fixes",
"aplica QW1 y CM2", Step 9 option 2). It turns the audit's findings (F#) and
recommendations (QW# / CM#) into applied, verified changes — without ever bypassing the
Golden Rules. All user-facing output stays in the report language chosen for the audit
(es / en / fr — see LANGUAGE in `SKILL.md`).

**Hard gates (all non-negotiable):**
- Only on explicit user request; confirm the exact scope (which IDs) before touching code.
- Never push, open PRs, or touch remotes without separate explicit consent.
- Never widen scope silently: one ID = one bounded change. New problems discovered while
  fixing become *candidate findings for the next audit*, not drive-by edits.
- Rule 6 applies verbatim: never claim a test ran or passed unless it was executed.

---

## 1. Pre-flight (once, before the first fix)

1. **Scope by IDs.** Restate which QW#/CM# will be applied and in which order — Quick Wins
   by severity first unless the user says otherwise. Ambiguous request → ask.
2. **Baseline.** Ensure a clean worktree; record the audited commit; create a work branch:
   `git checkout -b audit-fixes/<YYYY-MM-DD>`. If a test suite exists, run it once and
   record the result — that is the baseline no fix may degrade.
3. **No git / static mode:** skip branching; produce a unified-diff patch per fix and
   deliver the patches in chat with apply instructions (`git apply` / `patch -p1`). State
   clearly that nothing was applied to the user's copy.

## 2. Per-fix loop (repeat for each ID, in order)

1. **Re-verify the anchor.** Open the finding's `file:line`; confirm the defect still
   exists as described (mini-R2: if the code changed or the finding doesn't survive a
   re-read, say so and skip — don't "fix" a ghost).
2. **Design the minimal diff.** State the expected behavior change and blast radius;
   prefer the smallest change that removes the defect. Name the test that will prove it.
3. **Implement.** Apply the diff. Add or update a test when the ecosystem has a harness;
   if none exists, add the lightest possible repro check (or record why not).
4. **Verify.** Run the relevant tests/linters; re-check that the original evidence pattern
   is gone (targeted grep or re-run of the relevant recon section). Verification evidence
   goes in the report row — confidence Alta = executed, Media = reasoned only; label
   honestly.
5. **Commit.** One commit per fix: `fix(QW1): <summary>` (or `refactor(CM1): …`),
   referencing the audited commit in the body.
6. **On failure.** If the fix breaks the suite or verification fails twice, revert the
   commit, mark the ID `requiere decisión humana` with the reason, and move on. Never
   leave the branch red between fixes.

## 3. Model alternation during implementation

Routing policy is the same as Step 3.5 — see `model-routing.md` (primary continuity,
selective secondary, fallback = primary, live safeguard/quota check online, never route
around a safeguard, model-usage log). Implementation-specific additions:

- **When to delegate a fix:** several independent IDs touching disjoint files (parallel
  sub-agents), or a single CM# whose refactor is genuinely hard and multi-step (secondary,
  if permitted and clearly worth it). Trivial Quick Wins: don't delegate — footprint rule.
- **Expect security redirects.** Fix work on §4c-type findings (injection, secrets, auth,
  sanitization) is exactly what a cybersecurity classifier may redirect mid-task. That is
  normal operation, not an error: accept it, continue on the fallback, note it in the
  model-usage log.
- **Implementation sub-agent contract** (hand it verbatim, plus repo context):
  1. **Scope:** exactly one fix ID, its finding (F#), the evidence anchor, and the files
     it owns. Nothing else may be modified.
  2. It must run the **per-fix loop** above in full (re-verify → minimal diff → test →
     verify) — not a blank-slate improvisation.
  3. **Returns:** the diff, the verification evidence, and any new suspicions as
     *candidate findings*. It does NOT commit to shared history, widen scope, or write
     user-facing reports.
  4. The **Golden Rules** bind it in full (traceability, no fabricated test results).
- **Merge:** the orchestrator reviews all returned diffs together (cross-fix conflicts,
  duplicated helpers), applies and commits them, re-runs the full suite once at the end,
  and consolidates the model-usage log.

## 4. Output contract — the implementation report

Emit after the last fix, in the report language (the shape below is the Spanish one;
translate headings and labels, keep the `<implementacion>` tag and the IDs), separate from
the 9-section audit report:

```markdown
<implementacion>
## Informe de implementación
**Base:** `<commit auditado>` · **Rama:** `audit-fixes/<fecha>` · **Alcance:** QW1, QW2, CM1

| ID | Estado | Cambio | Verificación |
|----|--------|--------|--------------|
| QW1 | ✅ aplicado | `src/x.ts:40-52` | test `y` pasa; patrón original ausente (grep) |
| CM1 | ⏸ requiere decisión humana | — | rompe la suite: <motivo> (revertido) |

**Suite completa:** <verde/rojo + números, o "no ejecutada — sin harness">
**Model-usage log:** <tramo → rol/modelo → motivo (valor / bloqueo / redirección / cuota)>
**Siguiente paso sugerido:** <abrir PR / re-auditar — este informe es el prior de la
próxima auditoría / issues para los IDs pendientes>
</implementacion>

<nota_etica>
---
*Cambios generados con asistencia de IA. Requieren revisión humana antes de hacer merge.*
</nota_etica>
```

**Conformance quick-check (silent, before delivering):** every applied ID has executed
verification evidence · every skipped ID has a reason · suite status comes from real
execution (or says "no ejecutada") · model-usage log present whenever anything was
delegated · zero changes outside the scoped IDs.
