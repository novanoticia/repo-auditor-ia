#!/usr/bin/env bash
# run.sh — regression tests for scripts/recon.sh. Plain bash (3.2+), no
# dependencies beyond git; dependency auditors are replaced by stubs so the
# suite is offline and deterministic.
# Usage: bash tests/run.sh        (exit 0 = all green)

set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RECON="$ROOT/skills/auditar-repo/scripts/recon.sh"
STUBS="$ROOT/tests/stubs"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass=0; fail=0
ok()  { pass=$((pass + 1)); echo "  ok   $1"; }
ko()  { fail=$((fail + 1)); echo "  FAIL $1"; }
has() { printf '%s\n' "$OUT" | grep -qE -- "$1"; }
check()     { if has "$2"; then ok "$1"; else ko "$1"; fi; }    # pattern present
check_not() { if has "$2"; then ko "$1"; else ok "$1"; fi; }    # pattern absent
# section <name>: print one recon section of $OUT
section() { printf '%s\n' "$OUT" | awk -v s="== $1" 'index($0, s) == 1 {on=1; next} /^== / {on=0} on'; }

run_recon() { OUT="$(PATH="$STUBS:$PATH" bash "$RECON" "$1" 2>&1)"; RC=$?; }

TRAP="$WORK/trap"
bash "$ROOT/tests/make-trap-repo.sh" "$TRAP" || { echo "cannot build trap repo"; exit 1; }

echo "recon.sh — trap repo"
run_recon "$TRAP"
if [ "$RC" -eq 0 ]; then ok "exits 0"; else ko "exits 0 (got $RC)"; fi

# QW3 / F2 — tree shows .github but not .git internals
TREE="$(section 'TREE')"
if printf '%s\n' "$TREE" | grep -qx './.github'; then ok "tree lists .github"; else ko "tree lists .github"; fi
if printf '%s\n' "$TREE" | grep -qE '^\./\.git(/|$)'; then ko "tree hides .git"; else ok "tree hides .git"; fi

# QW4 / F4 — every planted secret format is detected (by its key)
for key in '"apiKey"' 'GITHUB_TOKEN=' 'AWS_SECRET_ACCESS_KEY=' 'settings.py:1:token' 'src_token:'; do
  check "secret detected: $key" "$key"
done
# QW4 / F5 — no planted value ever leaks past its first 4 chars
check_not "no planted value leaks (secrets + TODO samples)" 'Hx4mN8vR'
check "values masked as q7Zr***" 'q7Zr\*\*\*'

# QW1 / F1 — no lockfile => explicit skip, never an empty section
check "npm without lockfile: skipped"     'npm audit needs a lockfile'
check "cargo without Cargo.lock: skipped" 'cargo audit needs a lockfile'
# QW2 / F3 — pip-audit targets the repo's requirements, installs nothing
check "pip-audit audits requirements.txt" 'ARGS: -r requirements.txt --no-deps --disable-pip'

# Tri-state contract — every section ends with STATUS: ok|failed|skipped
missing="$(printf '%s\n' "$OUT" | awk '
  /^== END OF PACK ==/ { if (name != "" && !seen) print name; exit }
  /^== / { if (name != "" && !seen) print name; name = $0; seen = 0; next }
  /^STATUS: (ok|failed|skipped)/ { seen = 1 }')"
if [ -z "$missing" ]; then ok "every section carries a STATUS line"
else ko "every section carries a STATUS line (missing: $(echo "$missing" | tr '\n' ' '))"; fi

# Read-only invariant — recon never modifies the audited repo
if [ -z "$(git -C "$TRAP" status --porcelain)" ]; then ok "trap repo untouched"; else ko "trap repo untouched"; fi

echo "recon.sh — npm audit status with a lockfile"
printf '{}\n' > "$TRAP/package-lock.json"
for mode in clean:'STATUS: ok \(exit 0\)' vulns:'STATUS: ok \(exit 1: vulnerabilities' error:'STATUS: failed'; do
  OUT="$(STUB_NPM="${mode%%:*}" PATH="$STUBS:$PATH" bash "$RECON" "$TRAP" 2>&1)"
  check "npm ${mode%%:*} => ${mode#*:}" "${mode#*:}"
done
rm -f "$TRAP/package-lock.json"

echo "recon.sh — manifest present, auditor not installed"
# PATH with only the npm stub + system dirs: pip-audit and cargo-audit are
# guaranteed absent, so their manifests must still yield an explicit skip (G1).
NPM_ONLY="$WORK/npm-only"; mkdir -p "$NPM_ONLY"; cp "$STUBS/npm" "$NPM_ONLY/npm"
OUT="$(PATH="$NPM_ONLY:/usr/bin:/bin" "$BASH" "$RECON" "$TRAP" 2>&1)"
check "pip-audit missing => skipped, not silent"   'STATUS: skipped \(pip-audit not installed'
check "cargo-audit missing => skipped, not silent" 'STATUS: skipped \(cargo-audit not installed'

echo "recon.sh — pyproject-only Python repo"
PY="$WORK/py"; mkdir -p "$PY"; printf '[project]\nname = "x"\n' > "$PY/pyproject.toml"
run_recon "$PY"
check "pyproject only: skipped (would run project code)" 'pyproject.toml only'
check_not "pyproject only: pip-audit not invoked" 'ARGS:'

echo "recon.sh — unreadable file"
LOCKED="$WORK/locked"; mkdir -p "$LOCKED"; printf 'TODO x\n' > "$LOCKED/secret.txt"; chmod 000 "$LOCKED/secret.txt"
run_recon "$LOCKED"
chmod 644 "$LOCKED/secret.txt"
check "grep error => STATUS: failed, not a clean result" 'STATUS: failed \(grep exit 2'

echo "recon.sh — not a git repo"
PLAIN="$WORK/plain"; mkdir -p "$PLAIN"; printf 'x\n' > "$PLAIN/a.txt"
run_recon "$PLAIN"
if [ "$RC" -eq 0 ]; then ok "exits 0 without git"; else ko "exits 0 without git (got $RC)"; fi
check "commit section skipped without git" 'STATUS: skipped \(not a git repo'
check "hotspots skipped without git"       'STATUS: skipped \(not a git repo\)$'

echo "eval/check-report.sh — section order"
# A correct report that mentions a section inline ("ver `<epistemico>`") must
# not count as a duplicated section (G3).
RPT="$WORK/report.md"
{ for t in veredicto modelo_superior diagnostico hallazgos epistemico recomendaciones contexto; do
    printf '<%s>\n</%s>\n' "$t" "$t"; done
  printf '<limites>\nHipótesis pendientes (ver `<epistemico>`).\n</limites>\n<nota_etica>\n</nota_etica>\n'
} > "$RPT"
OUT="$(bash "$ROOT/tests/eval/check-report.sh" "$RPT" 2>&1)"
check     "inline section mention is not a duplicate" 'ok   9 XML sections in fixed order'
printf '<veredicto>\n</veredicto>\n<hallazgos>\n</hallazgos>\n<diagnostico>\n</diagnostico>\n' > "$RPT"
OUT="$(bash "$ROOT/tests/eval/check-report.sh" "$RPT" 2>&1)"
check     "out-of-order sections still fail"          'FAIL 9 XML sections in fixed order'

echo
echo "passed: $pass  failed: $fail"
[ "$fail" -eq 0 ]
