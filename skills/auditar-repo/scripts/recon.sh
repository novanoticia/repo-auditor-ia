#!/usr/bin/env bash
# recon.sh — deterministic reconnaissance evidence pack (Step 3 of the audit).
# Read-only: never modifies the repo. Degrades gracefully when a tool, network,
# or git history is missing (prints "n/a" instead of failing).
# Usage: bash scripts/recon.sh [repo-dir]     (default: current directory)

set -u
REPO="${1:-.}"
cd "$REPO" 2>/dev/null || { echo "ERROR: cannot cd to '$REPO'" >&2; exit 1; }

EXCL="--exclude-dir=.git --exclude-dir=node_modules --exclude-dir=vendor --exclude-dir=dist --exclude-dir=build --exclude-dir=__pycache__ --exclude-dir=.venv"
SECRET_PAT='(api[_-]?key|secret|passw(or)?d|token|private[_-]?key)[[:space:]]*[:=][[:space:]]*["'\''][A-Za-z0-9/+_-]{12,}'

section() { printf '\n== %s ==\n' "$1"; }
has_git() { git rev-parse HEAD >/dev/null 2>&1; }

echo "RECON EVIDENCE PACK — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "dir: $(pwd)"

section "COMMIT / REF"
if has_git; then
  git rev-parse HEAD
  git describe --tags --always 2>/dev/null || true
else
  echo "n/a (not a git repo — no history-based checks available)"
fi

section "STACK MANIFESTS (root)"
found=0
for f in package.json pyproject.toml setup.py requirements.txt go.mod Cargo.toml \
         composer.json Gemfile pom.xml build.gradle Makefile Dockerfile docker-compose.yml; do
  [ -e "$f" ] && { echo "$f"; found=1; }
done
[ "$found" -eq 0 ] && echo "none detected at root"

section "AI/AGENT & PLUGIN ARTIFACTS"
found=0
for f in SKILL.md AGENTS.md CLAUDE.md .cursorrules .cursor/rules mcp.json .mcp.json \
         manifest.json plugin.json .claude-plugin; do
  [ -e "$f" ] && { echo "$f"; found=1; }
done
[ "$found" -eq 0 ] && echo "none detected"

section "TREE (2 levels, capped at 80 entries)"
# Exact-dir exclusions: a './.git*' prefix would also hide .github/ (CI workflows).
find . -maxdepth 2 \
  -not -path './.git' -not -path './.git/*' \
  -not -path './node_modules' -not -path './node_modules/*' \
  -not -path './.venv' -not -path './.venv/*' \
  | sort | head -80

section "SIZE"
printf 'files (excl. .git/node_modules): '
find . -type f -not -path './.git/*' -not -path './node_modules/*' | wc -l

section "LARGEST SOURCE FILES (KB, top 10, lockfiles excluded)"
find . -type f -not -path './.git/*' -not -path './node_modules/*' \
     -not -name '*.lock' -not -name 'package-lock.json' -not -name 'yarn.lock' \
     -exec du -k {} + 2>/dev/null | sort -rn | head -10

section "GIT HOTSPOTS (churn, last 6 months, top 15)"
if has_git; then
  git log --since="6 months ago" --name-only --format= 2>/dev/null \
    | grep -v '^$' | sort | uniq -c | sort -rn | head -15
else
  echo "n/a"
fi

section "RECENT COMMITS (15)"
if has_git; then git log --oneline -15; else echo "n/a"; fi

section "TODO/FIXME/HACK DENSITY"
printf 'total occurrences: '
grep -rniE '\b(TODO|FIXME|HACK|XXX)\b' $EXCL . 2>/dev/null | wc -l
echo "sample lines (top 10 — discard self-referential/doc mentions before counting as debt):"
grep -rniE '\b(TODO|FIXME|HACK|XXX)\b' $EXCL . 2>/dev/null | head -10

section "SECRET HEURISTICS (candidates only — verify manually, Rule 6)"
# Values are masked (first 4 chars + ***) so secrets never land in the agent's context.
hits=$(grep -rniE "$SECRET_PAT" $EXCL . 2>/dev/null | head -10 \
  | sed -E "s/([:=][[:space:]]*[\"'])([A-Za-z0-9\/+_-]{4})[A-Za-z0-9\/+_-]*/\1\2***/g")
if [ -n "$hits" ]; then echo "$hits"; else echo "no obvious hits (heuristic, not proof of absence)"; fi

section "DEPENDENCY AUDIT (runs only if tooling is present)"
# run_audit <label> <cmd...> — runs one auditor and ALWAYS prints a STATUS line,
# so an empty section can never be mistaken for a clean result. A non-zero exit
# is not a failure by itself: npm, pip-audit and cargo-audit all exit non-zero
# when they *find* vulnerabilities.
run_audit() {
  label=$1; shift
  echo "-- $label (tail 15) --"
  out=$("$@" 2>&1); rc=$?
  printf '%s\n' "$out" | tail -15
  if [ "$rc" -eq 0 ]; then
    echo "STATUS: ok (exit 0)"
  elif printf '%s\n' "$out" | grep -qiE 'vulnerabilit' \
       && ! printf '%s\n' "$out" | grep -qE '^npm (error|ERR!)'; then
    echo "STATUS: ok (exit $rc: vulnerabilities reported)"
  else
    echo "STATUS: failed (exit $rc) — output above is NOT a clean result; declare it in <limites>"
  fi
}
ran=0
if [ -f package.json ] && command -v npm >/dev/null 2>&1; then
  ran=1
  if [ -f package-lock.json ] || [ -f npm-shrinkwrap.json ]; then
    run_audit "npm audit" npm audit --omit=dev
  else
    echo "-- npm audit --"
    echo "STATUS: skipped (no package-lock.json/npm-shrinkwrap.json — npm audit needs a lockfile)"
  fi
fi
if { [ -f pyproject.toml ] || [ -f requirements.txt ]; } && command -v pip-audit >/dev/null 2>&1; then
  ran=1
  # Bare `pip-audit` audits the *auditor's* Python environment, not the repo.
  # --no-deps --disable-pip checks the pinned requirements without installing
  # anything; `pip-audit .` would build the project, i.e. run its code (Rule 7).
  if [ -f requirements.txt ]; then
    run_audit "pip-audit" pip-audit -r requirements.txt --no-deps --disable-pip
  else
    echo "-- pip-audit --"
    echo "STATUS: skipped (pyproject.toml only — auditing it would build the project and run its code; review dependencies manually)"
  fi
fi
if [ -f Cargo.toml ] && command -v cargo-audit >/dev/null 2>&1; then
  ran=1
  if [ -f Cargo.lock ]; then
    run_audit "cargo audit" cargo audit
  else
    echo "-- cargo audit --"
    echo "STATUS: skipped (no Cargo.lock — cargo audit needs a lockfile)"
  fi
fi
if [ "$ran" -eq 0 ]; then
  echo "STATUS: skipped (no audit tooling for the detected manifests — declare it in <limites> and reason manually from manifests)"
fi

printf '\n== END OF PACK ==\n'
exit 0
