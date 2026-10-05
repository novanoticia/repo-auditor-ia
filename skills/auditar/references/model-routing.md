# Model-Routing Reference — frontier-model orchestration

This file backs **Step 3.5** of the skill. It is a **lookup procedure**, not a fixed rule:
it deliberately names no specific model version, because model line-ups, quotas and
safeguards change faster than this file. Route by *role* (primary / secondary / fallback),
verify live constraints online at run time, and use whatever frontier models are current.
Read this file only when you actually delegate.

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
  time-boxed?
- **(c) Redirect target** — when a safeguard fires, which model does the request go to?

**Query patterns** (substitute the real model/provider):
- `"<model> safeguards permitted use redirect"`
- `"<model> quota weekly usage limit availability"`
- `"<provider> usage policy cybersecurity"`

**Prefer primary sources:** the provider's own usage policy, model release notes and
documentation pages. Treat press coverage as secondary.

If you cannot reach the web, **do not delegate to a secondary model**: keep the whole flow
on the current session's model (the primary) and record the unverified assumption in
`<limites>` (Rule 6 — don't present unverified policy as current fact).

---

## 2. Roles (model-agnostic — this is the durable part)

- **Primary reasoner (default for the whole flow).** The most capable model that *also*
  maximizes continuity — least likely to hit a quota cap, an availability window, or a
  safeguard redirect mid-task. Runs analysis **and** implementation by default. When in
  doubt, the primary is the model the session is already running on.
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

## 3. Worked pattern (generic)

A typical, valid routing decision looks like this — fill in real names only after §1:

1. §1 shows that model **A** is fully available with no tight quota, and model **B** is
   stronger on long multi-step reasoning but quota-limited and runs a broad cybersecurity
   classifier.
2. → **A is primary** (continuity): it runs the whole audit and every fix by default.
3. → **B is secondary**, called only for one genuinely hard, permitted slice (for example,
   the architecture axis of a very large monorepo).
4. Security-axis work (§4c) and security fixes stay on A: they are exactly what B's
   classifier may redirect, so routing them to B would add interruptions without value.
5. If B redirects or runs out of quota mid-slice, A finishes the slice; the model-usage log
   records `B → A (redirección)` or `B → A (cuota)`.

---

## 4. Mapping roles onto the host

Use whatever sub-agent mechanism the host offers. In Claude Code / Cowork, that is the
agent tool's `model` override, which takes a model alias; pick the alias that §1 placed in
each role. Elsewhere, use the provider's equivalent.

Naming models here is **routing configuration** — a *compatible usage context*, not the
report's stated engine — so it does not breach the Model-Naming Constraint.

---

## 5. Adopting a new model

To onboard a newer frontier model: check its live policy (§1), then slot it into the role it
best fits — *most capable + most continuous* → primary; *complementary/specialized but
quota- or safeguard-limited* → secondary. No edit to this file is needed: the roles are the
contract, the models are runtime choices.
