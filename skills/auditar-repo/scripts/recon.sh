#!/usr/bin/env bash
# recon.sh — deterministic reconnaissance evidence pack (Step 3 of the audit).
# Read-only: never modifies the repo. Degrades gracefully when a tool, network,
# or git history is missing instead of failing.
#
# Output contract (tri-state): every section ends with one or more lines
#   STATUS: ok | failed | skipped (<reason>)
# "ok" means the check really ran; only "ok" evidence may be cited with
# confidence Alta. "failed"/"skipped" must be declared in <limites> — an empty
# section is never a clean result.
# Usage: bash scripts/recon.sh [--json] [repo-dir]   (default: current directory)
#   --json  the same pack as JSON (schema repo-auditor-ia/recon@1): one object per
#           section with its worst status (failed > skipped > ok), every STATUS line
#           with its check name, and the content lines.

# shellcheck disable=SC2086  # $EXCL is word-split into grep flags on purpose
set -u

# to_json — converts the text pack (stdin) to JSON. Built on the text output so the
# two formats can never drift apart. Fails closed: a section without a STATUS line,
# or with an unknown status word, is reported as "failed".
to_json() {
  LC_ALL=C tr -d '\000-\010\013\014\016-\037' | awk '
  # JSON string escape, char by char: gsub replacement strings treat backslashes
  # differently in BSD awk, gawk and mawk; plain string literals do not.
  function q(s,   out, i, c) {
    out = ""
    for (i = 1; i <= length(s); i++) {
      c = substr(s, i, 1)
      if (c == "\\") c = "\\\\"; else if (c == "\"") c = "\\\""
      else if (c == "\t") c = "\\t"; else if (c == "\r") c = "\\r"
      out = out c
    }
    return "\"" out "\""
  }
  function rank(x) { return x == "failed" ? 2 : (x == "skipped" ? 1 : 0) }
  function header() {
    if (started) return
    started = 1
    printf "{\n  \"schema\": \"repo-auditor-ia/recon@1\",\n  \"generated_at\": %s,\n  \"dir\": %s,\n  \"sections\": [", q(gen), q(dir)
  }
  function flush(   i, worst) {
    if (name == "") return
    if (ns == 0) { ns = 1; sc[1] = name; ss[1] = "failed"; sr[1] = "(no STATUS line: treated as failed)" }
    worst = "ok"
    for (i = 1; i <= ns; i++) if (rank(ss[i]) > rank(worst)) worst = ss[i]
    n[worst]++
    printf "%s\n    {\"name\": %s, \"status\": %s, \"statuses\": [", (nsec++ ? "," : ""), q(name), q(worst)
    for (i = 1; i <= ns; i++)
      printf "%s{\"check\": %s, \"status\": %s, \"reason\": %s}", (i > 1 ? ", " : ""), q(sc[i]), q(ss[i]), q(sr[i])
    printf "], \"lines\": ["
    for (i = 1; i <= nl; i++) printf "%s%s", (i > 1 ? ", " : ""), q(ln[i])
    printf "]}"
    name = ""; ns = 0; nl = 0
  }
  NR == 1 && /^RECON EVIDENCE PACK/ { gen = $0; sub(/^RECON EVIDENCE PACK[^0-9]*/, "", gen); next }
  /^dir: /                 { dir = substr($0, 6); next }
  /^contract: /            { next }
  /^== END OF PACK ==$/    { flush(); next }
  /^== .* ==$/             { flush(); header(); name = substr($0, 4, length($0) - 6); check = name; next }
  /^-- .* --$/             { check = substr($0, 4, length($0) - 6); sub(/ \(tail [0-9]+\)$/, "", check); next }
  /^STATUS: /              {
    s = substr($0, 9); st = s; sub(/ .*/, "", st)
    r = (length(s) > length(st)) ? substr(s, length(st) + 2) : ""
    if (st != "ok" && st != "skipped" && st != "failed") { r = "(unknown status \"" st "\") " r; st = "failed" }
    ns++; sc[ns] = check; ss[ns] = st; sr[ns] = r; next
  }
  name != "" && $0 != ""   { ln[++nl] = $0 }
  END {
    flush(); header()
    printf "\n  ],\n  \"summary\": {\"ok\": %d, \"skipped\": %d, \"failed\": %d}\n}\n", n["ok"], n["skipped"], n["failed"]
  }'
}

# main — the recon pack itself. A function so that --json can call it directly
# instead of re-running this file.
main() {
REPO="${1:-.}"
cd "$REPO" 2>/dev/null || { echo "ERROR: cannot cd to '$REPO'" >&2; exit 1; }

EXCL="--exclude-dir=.git --exclude-dir=node_modules --exclude-dir=vendor --exclude-dir=dist --exclude-dir=build --exclude-dir=__pycache__ --exclude-dir=.venv"
# Key may carry a suffix (AWS_SECRET_ACCESS_KEY, GITHUB_TOKEN), a closing quote
# (JSON "apiKey": ...) and an unquoted value (.env files).
KEYVAL_REGEX='(api[_-]?key|secret|passw(or)?d|token|private[_-]?key)[A-Za-z0-9_]*["'\'']?[[:space:]]*[:=][[:space:]]*["'\'']?[A-Za-z0-9/+_.-]{12,}'

section() { printf '\n== %s ==\n' "$1"; }
status()  { echo "STATUS: $*"; }
# grep_status <rc> — grep exits 0 (match) / 1 (no match) / 2 (error).
grep_status() {
  if [ "$1" -le 1 ]; then status "ok"
  else status "failed (grep exit $1 — results may be partial)"; fi
}
has_git() { git rev-parse HEAD >/dev/null 2>&1; }

# mask_secrets — filter that keeps each key-anchored value's first 4 chars and
# replaces the rest with *** (values of 8 chars or fewer are fully masked), so
# the key name stays as evidence but the value never reaches the agent.
# Case-insensitive via tolower(): sed's I flag is GNU-only.
mask_secrets() {
  awk '
  BEGIN { key = "(api[_-]?key|secret|passw(or)?d|token|private[_-]?key)[a-z0-9_]*[\"'\'']?[[:space:]]*[:=][[:space:]]*[\"'\'']?" }
  {
    rest = $0; out = ""
    while (match(tolower(rest), key)) {
      out = out substr(rest, 1, RSTART + RLENGTH - 1)
      rest = substr(rest, RSTART + RLENGTH)
      if (match(rest, /^[^[:space:]"'\'',;}]+/)) {
        out = out (RLENGTH > 8 ? substr(rest, 1, 4) : "") "***"
        rest = substr(rest, RLENGTH + 1)
      }
    }
    print out rest
  }'
}

# find_named <maxdepth> <pattern...> — paths (./a/b) whose name matches a pattern
# (a pattern containing "/" is matched against the path suffix instead), pruning
# VCS, vendored and build dirs. Sorted, so repeated runs print identical output.
find_named() {
  depth=$1; shift
  expr=""
  for p in "$@"; do
    case "$p" in
      */*) expr="$expr -o -path '*/$p'" ;;
      *)   expr="$expr -o -name '$p'" ;;
    esac
  done
  eval "find . -maxdepth $depth \
    \( -name .git -o -name node_modules -o -name vendor -o -name dist -o -name build \
       -o -name __pycache__ -o -name .venv \) -prune \
    -o \( ${expr# -o } \) -print" 2>/dev/null | sort
}

echo "RECON EVIDENCE PACK — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "dir: $(pwd)"
echo "contract: every section ends with STATUS: ok | failed | skipped — only 'ok' evidence may be cited with confidence Alta"

section "COMMIT / REF"
if has_git; then
  git rev-parse HEAD
  git describe --tags --always 2>/dev/null || true
  status "ok"
else
  status "skipped (not a git repo — no history-based checks available)"
fi

section "STACK MANIFESTS (depth <= 3)"
manifest_list=$(find_named 3 package.json pyproject.toml setup.py requirements.txt go.mod \
  Cargo.toml composer.json Gemfile pom.xml build.gradle Makefile Dockerfile docker-compose.yml)
if [ -n "$manifest_list" ]; then printf '%s\n' "$manifest_list"; else echo "none detected"; fi
status "ok (depth <= 3; vendored/build dirs excluded)"

section "AI/AGENT & PLUGIN ARTIFACTS (depth <= 4)"
artifacts=$(find_named 4 SKILL.md AGENTS.md CLAUDE.md GEMINI.md .cursorrules .cursor/rules \
  mcp.json .mcp.json manifest.json plugin.json .claude-plugin .github/copilot-instructions.md)
if [ -n "$artifacts" ]; then printf '%s\n' "$artifacts"; else echo "none detected"; fi
status "ok (depth <= 4; vendored/build dirs excluded)"

section "TREE (2 levels, capped at 80 entries)"
# Exact-dir exclusions: a './.git*' prefix would also hide .github/ (CI workflows).
find . -maxdepth 2 \
  -not -path './.git' -not -path './.git/*' \
  -not -path './node_modules' -not -path './node_modules/*' \
  -not -path './.venv' -not -path './.venv/*' \
  | sort | head -80
status "ok"

section "SIZE"
printf 'files (excl. .git/node_modules): '
find . -type f -not -path './.git/*' -not -path './node_modules/*' | wc -l
status "ok"

section "LARGEST SOURCE FILES (KB, top 10, lockfiles excluded)"
find . -type f -not -path './.git/*' -not -path './node_modules/*' \
     -not -name '*.lock' -not -name 'package-lock.json' -not -name 'yarn.lock' \
     -exec du -k {} + 2>/dev/null | sort -rn | head -10
status "ok"

section "GIT HOTSPOTS (churn, last 6 months, top 15)"
if has_git; then
  # Renames are followed: log is newest-first, so each "R old new" maps the old
  # path (and every older change to it) onto the file's current name.
  git log --since="6 months ago" -M --name-status --format= 2>/dev/null | awk -F '\t' '
    $1 ~ /^R/ { cur = ($3 in final) ? final[$3] : $3; final[$2] = cur; n[cur]++; next }
    NF >= 2   { cur = ($2 in final) ? final[$2] : $2; n[cur]++ }
    END       { for (f in n) printf "%4d %s\n", n[f], f }' \
    | sort -k1,1rn -k2,2 | head -15
  status "ok (renames followed)"
else
  status "skipped (not a git repo)"
fi

section "RECENT COMMITS (15)"
if has_git; then git log --oneline -15; status "ok"; else status "skipped (not a git repo)"; fi

section "TODO/FIXME/HACK DENSITY"
todo=$(grep -rniE '\b(TODO|FIXME|HACK|XXX)\b' $EXCL . 2>/dev/null); rc=$?
echo "total occurrences: $(printf '%s' "$todo" | grep -c .)"
echo "sample lines (top 10 — discard self-referential/doc mentions before counting as debt):"
[ -n "$todo" ] && printf '%s\n' "$todo" | head -10 | mask_secrets
grep_status "$rc"

section "SECRET HEURISTICS (candidates only — verify manually, Rule 6)"
# Values are masked (see mask_secrets) so secrets never land in the agent's context.
raw=$(grep -rniE "$KEYVAL_REGEX" $EXCL . 2>/dev/null); rc=$?
hits=$(printf '%s\n' "$raw" | head -10 | mask_secrets); unset raw
if [ -n "$hits" ]; then echo "$hits"; else echo "no obvious hits (heuristic, not proof of absence)"; fi
grep_status "$rc"

section "DEPENDENCY AUDIT (one STATUS per detected manifest)"
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
# One block per detected manifest: each ALWAYS ends in a STATUS line, including
# when its auditor is not installed (a missing tool is a skip, never silence).
skip() { echo "-- $1 --"; status "skipped ($2)"; }
manifests=0
if [ -f package.json ]; then
  manifests=1
  if ! command -v npm >/dev/null 2>&1; then
    skip "npm audit" "npm not installed — review package.json manually"
  elif [ -f package-lock.json ] || [ -f npm-shrinkwrap.json ]; then
    run_audit "npm audit" npm audit --omit=dev
  else
    skip "npm audit" "no package-lock.json/npm-shrinkwrap.json — npm audit needs a lockfile"
  fi
fi
if [ -f pyproject.toml ] || [ -f requirements.txt ]; then
  manifests=1
  # Bare `pip-audit` audits the *auditor's* Python environment, not the repo.
  # --no-deps --disable-pip checks the pinned requirements without installing
  # anything; `pip-audit .` would build the project, i.e. run its code (Rule 7).
  if ! command -v pip-audit >/dev/null 2>&1; then
    skip "pip-audit" "pip-audit not installed — review Python dependencies manually"
  elif [ -f requirements.txt ]; then
    run_audit "pip-audit" pip-audit -r requirements.txt --no-deps --disable-pip
  else
    skip "pip-audit" "pyproject.toml only — auditing it would build the project and run its code; review dependencies manually"
  fi
fi
if [ -f Cargo.toml ]; then
  manifests=1
  if ! command -v cargo-audit >/dev/null 2>&1; then
    skip "cargo audit" "cargo-audit not installed — review Cargo.toml manually"
  elif [ -f Cargo.lock ]; then
    run_audit "cargo audit" cargo audit
  else
    skip "cargo audit" "no Cargo.lock — cargo audit needs a lockfile"
  fi
fi
if [ "$manifests" -eq 0 ]; then
  status "skipped (no npm/Python/Cargo manifest at root — nothing to audit automatically)"
fi
# Auditors run at the root only: nested manifests are declared, never silent (F9).
nested=$(find_named 3 package.json requirements.txt pyproject.toml Cargo.toml | grep -c '^\./.*/')
if [ "$nested" -gt 0 ]; then
  echo "-- nested manifests --"
  status "skipped (nested manifests not audited: $nested — see STACK MANIFESTS; review manually)"
fi

printf '\n== END OF PACK ==\n'
}

# --json: run the text pack first (no partial JSON if it fails), then convert it.
if [ "${1:-}" = "--json" ]; then
  shift
  pack=$(main "$@") || exit $?
  printf '%s\n' "$pack" | to_json
  exit 0
fi

main "$@"
exit 0
