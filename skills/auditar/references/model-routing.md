# Model-Routing Reference — frontier-model orchestration

This file backs **Step 3.5** of the skill. It is a **lookup procedure plus a dated worked
example**, not a fixed rule. The named models below **will go stale** — route by *role*
(primary / secondary / fallback), verify live constraints online, and swap in whatever
frontier models are current. Read this file only when you actually delegate.

The guiding idea: exploit the strengths of *several* frontier models while **honoring each
one's safeguards and permitted-use policy** — never hardcoding, never bypassing.

---

## 1. Check current constraints online (do this BEFORE routing)

Model constraints move fast: quotas, availability windows, and what each model is *allowed*
to handle all change. For each candidate model, web-search the provider's live policy and
skim for:

- **(a) Permitted vs. blocked/redirected** — which topics it handles vs. which get blocked
  or handed off to another model.
- **(b) Quota / availability window** — is it included fully, capped to a share of usage, or
  time-boxed to a redeploy window?
- **(c) Redirect target** — when a safeguard fires, which model does the request go to?

**Query patterns** (substitute the real model/provider):
- `"<model> safeguards permitted use redirect"`
- `"<model> quota weekly usage limit availability window"`
- `"<provider> usage policy responsible scaling cybersecurity biology"`

**Starting sources (Anthropic ecosystem, as an example):**
- Provider policy / responsible scaling: `anthropic.com/responsible-scaling-policy`,
  `anthropic.com/responsible-scaling-policy/roadmap`,
  `anthropic.com/responsible-scaling-policy/updates`, `anthropic.com/policy`.
- The specific model's release/redeploy note, e.g. `anthropic.com/news/redeploying-fable-5`.

If you cannot reach the web, fall back to the dated example below **and record the
assumption in `<limites>`** (Rule 6 — don't present stale policy as current fact).

---

## 2. Roles (model-agnostic — this is the durable part)

- **Primary reasoner (default for the whole flow).** The most capable model that *also*
  maximizes continuity — least likely to hit a quota cap, an availability window, or a
  safeguard redirect mid-task. Runs analysis **and** implementation by default.
- **Secondary / specialist (selective).** A complementary frontier model, invoked **only**
  for the hardest, most ambiguous, multi-step stretches, and only when it is permitted, has
  quota, and adds clear reasoning value.
- **Fallback = primary.** If the secondary is blocked, redirected by its own safeguards, or
  out of quota/window, continue that step on the primary **without stopping the flow.**

**Never route around a safeguard.** If a model is blocked/redirected on a topic, accept the
redirect and run that slice on whatever model the provider hands it to. Safeguards are
honored, not defeated.

*Implementation phase (Step 10):* the same roles apply when applying fixes; the
implementation-specific sub-agent contract and the security-redirect expectations live in
`implementation-mode.md`.

---

## 3. Dated worked example — verified as of 2026-07-06 (VERIFY again before relying on it)

**Primary = Opus 4.8** (continuity model). Full frontier capability, no tight inclusion
window → runs the whole audit + implementation by default. This is why the policy is
**Opus-priority**: it guarantees the flow won't stall on a quota cap or a closing window.

**Secondary = Fable 5** (specialist, selective). Use only on genuinely hard, ambiguous,
multi-step stretches, when permitted and quota remains. Known constraints (see Sources):

- Redeployed **2026-07-01** (after the export-controls lift of 2026-06-30) with a
  strengthened **cybersecurity classifier**; blocked requests are **redirected to
  Opus 4.8** and the user is notified.
- **Blocked/redirected topics:** cyber-exploitation / vulnerability discovery, CBRN
  (chemical/biological), and model-distillation. Per Anthropic, the deliberately broad
  classifier can *also* trip on some **routine secure-coding/debugging**.
  → On this skill's **security axis (§4c)** and secure-code refactors, **expect** redirects
  to Opus 4.8 and treat them as normal, not as errors.
- **Quota / window:** included up to **~50% of weekly usage limit through 2026-07-07**,
  afterwards available via usage credits. **If today is past 2026-07-07, assume the
  inclusion window has closed unless verified online.** Governed by the Responsible
  Scaling Policy (ASL-3 / CBRN classifiers).

**Consequence / why Opus-priority:** the Fable 5 inclusion window is closing *and* its
safeguards redirect exactly the security-sensitive work this skill does — so defaulting to
**Opus 4.8 as primary** maximizes continuity. Call Fable 5 in only for a genuinely hard,
permitted slice where it adds value.

---

## 4. Concrete mapping (Claude / Cowork usage context)

Spawn sub-agents via the agent tool's `model` override:

- primary  → `model: "opus"`  (example: Opus 4.8)
- secondary → `model: "fable"` (example: Fable 5)

Substitute your own provider/models elsewhere. Naming models here is **routing
configuration / a dated example** — a *compatible usage context*, not the report's stated
engine — so it does not breach the Model-Naming Constraint.

---

## 5. Adopting a future model (keep this file from rotting)

To onboard a newer frontier model: check its live policy (§1), then slot it into the role it
best fits — *most capable + most continuous* → primary; *complementary/specialized but
quota- or safeguard-limited* → secondary. Then **update or delete the dated example in §3**.
Never treat the model names above as permanent; they are an illustration, not the contract.

---

## Sources (checked 2026-07-06)

- https://www.anthropic.com/news/redeploying-fable-5
- https://www.anthropic.com/responsible-scaling-policy
- https://www.anthropic.com/responsible-scaling-policy/roadmap
- https://www.searchenginejournal.com/anthropics-claude-fable-5-is-back-with-new-usage-limits-and-safeguards/581231/
- https://www.digitaltrends.com/computing/youll-be-able-to-use-claude-fable-5-again-starting-july-1/
- https://www.infosecurity-magazine.com/news/anthropic-fable-mythos-back/
