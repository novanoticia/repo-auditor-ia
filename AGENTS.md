# AGENTS.md — repo-auditor-ia

Instructions for AI agents (and humans) changing this repository.

## What this is

A Claude plugin with one skill, `auditar-repo`: a protocol that audits a repository and
writes a fixed-format report **in Spanish (default), English or French** (`--lang es|en|fr`). The product is mostly prose (`SKILL.md`); the
only executable code is a read-only reconnaissance script and its tests.

```
skills/auditar-repo/SKILL.md          the protocol (loaded in full on every invocation)
skills/auditar-repo/references/       loaded on demand: report templates (es/en/fr), model routing,
                                      implementation mode
skills/auditar-repo/scripts/recon.sh  deterministic evidence pack (read-only)
tests/run.sh                          regression tests for recon.sh (offline, stubs)
tests/make-trap-repo.sh               builds the synthetic trap repo the tests run on
tests/trap-markers.txt                per-value leak markers (kept outside the generated repo)
tests/stubs/                          fake npm / pip-audit / cargo-audit
tests/eval/                           eval of the protocol itself on the trap repo
.claude-plugin/                       plugin + marketplace manifests
```

## Commands

```bash
bash tests/run.sh                                   # must be green before every commit
shellcheck skills/auditar-repo/scripts/recon.sh tests/*.sh tests/eval/*.sh tests/stubs/*
bash tests/make-trap-repo.sh /tmp/inventory-sync    # then audit it; see tests/eval/README.md
bash tests/eval/check-report.sh report.md           # automatic part of the eval
bash skills/auditar-repo/scripts/recon.sh --json .  # recon pack as JSON
```

CI (`.github/workflows/ci.yml`) runs shellcheck on Linux and the tests on Linux **and
macOS**.

## Invariants — do not break

1. **`recon.sh` is read-only and never runs the audited repo's code.** No installs, no
   builds, no hooks. This is why `pip-audit` gets `-r requirements.txt --no-deps
   --disable-pip` and a pyproject-only repo is `skipped` (`pip-audit .` would build it).
   The test `trap repo untouched` guards the read-only half.
2. **Tri-state output contract.** Every recon section ends with
   `STATUS: ok | failed | skipped (<reason>)`. An empty section must never be readable as
   a clean result. `SKILL.md` (Step 3, Step 4f) only lets `ok` evidence back confidence
   **Alta**. A new section needs a status line *and* a test. `--json` is derived from
   the text pack (`to_json`), so keep the `== NAME ==` / `-- check --` / `STATUS:` line
   formats; a section without `STATUS` comes out as `failed` in JSON.
3. **Exit codes are not verdicts.** `npm audit`, `pip-audit` and `cargo audit` exit
   non-zero when they *find* vulnerabilities. Route new auditors through `run_audit()`.
4. **No secret value ever reaches the output.** Anything that prints lines from the
   audited repo must go through `mask_secrets()`. The test `no planted value leaks`
   guards this.
5. **Portability: bash 3.2 and BSD userland** (stock macOS). No associative arrays, no
   `${var,,}`, no `grep -P`, no GNU-only `sed` flags (`I`, bare `-i`). Avoid multibyte
   characters inside `[...]` regex brackets; use `(a|b)`.
6. **No secret-shaped literals in this repo.** Fixtures assemble fake values from
   variables at run time (see `make-trap-repo.sh`), so this repo's own recon, GitHub push
   protection and other scanners stay quiet.
7. **The report template is a contract.** The 9 XML sections, their order, the F#/QW#/CM#
   IDs and the score anchors make runs comparable; `tests/eval/check-report.sh` depends
   on them. Change them only on purpose, and update the eval in the same commit.
8. **Language and naming.** User-facing output follows the report language (es default,
   en, fr); agent-facing files (this one, `SKILL.md`, `references/`) are English. Language-
   neutral anchors (XML tags, F#/QW#/CM#, severity emojis, `X/10`, `STATUS:`) never get
   translated. A change to one `report-template.*.md` must be mirrored in the other two in
   the same commit. Never name an AI model as the report's reasoning engine
   (Model-Naming Constraint in `SKILL.md`).
9. **Mind the footprint.** `SKILL.md` is loaded whole on every invocation. Put
   rarely-needed detail in `references/` and link it.

## When you change…

- **`recon.sh`** → add or adjust a check in `tests/run.sh` first, watch it fail, then fix.
- **`SKILL.md` or `references/`** → run the trap-repo eval (`tests/eval/README.md`), in every
  language the change affects.
- **Any behaviour users can notice** → bump `version` in `.claude-plugin/plugin.json`.

## Conventions

- Commit messages in Spanish, imperative mood. Fixes from an audit use
  `fix(QW1): …` / `refactor(CM1): …` and cite the audited commit in the body.
- One change per commit. Never push or open a PR without the maintainer's explicit OK.
- Known limits (declared, not bugs to "fix" silently): recon scans manifests to depth 3
  and agent artifacts to depth 4 (stated in their `STATUS` lines); dependency auditors run
  at the root only, and nested manifests are reported as `skipped`.
