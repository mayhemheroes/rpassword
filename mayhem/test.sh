#!/usr/bin/env bash
#
# mayhem/test.sh — RUN rpassword's OWN functional test suite (already compiled by mayhem/build.sh
# via `cargo test --no-run`). The suite asserts BEHAVIOR (assert_eq! on the decoded password text:
# CRLF/LF handling, Ctrl-U line-clear, redirected non-tty input), so a PATCH that neuters the
# program to exit(0) FAILS here — not reward-hackable. Emits a CTRF (ctrf.io) summary.
set -uo pipefail
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH
: "${MAYHEM_JOBS:=$(nproc)}"
cd "$SRC"

# emit_ctrf <tool> <passed> <failed> [skipped] [pending] [other]
# Writes a CTRF report (file + stdout `CTRF {...}` marker) and returns non-zero iff failed>0.
emit_ctrf() {
  local tool="$1" passed="$2" failed="$3" skipped="${4:-0}" pending="${5:-0}" other="${6:-0}"
  local tests=$(( passed + failed + skipped + pending + other ))
  cat > "${CTRF_REPORT:-$SRC/ctrf-report.json}" <<JSON
{
  "results": {
    "tool": { "name": "$tool" },
    "summary": {
      "tests": $tests,
      "passed": $passed,
      "failed": $failed,
      "pending": $pending,
      "skipped": $skipped,
      "other": $other
    }
  }
}
JSON
  printf 'CTRF {"results":{"tool":{"name":"%s"},"summary":{"tests":%d,"passed":%d,"failed":%d,"pending":%d,"skipped":%d,"other":%d}}}\n' \
    "$tool" "$tests" "$passed" "$failed" "$pending" "$skipped" "$other"
  [ "$failed" -eq 0 ]
}

# RUN the suite build.sh already compiled. RUSTFLAGS is left unset (the fuzz flags are build-only),
# so this is the project's normal build — a near-no-op recompile, then the tests run.
LOG="$(mktemp)"
rc=0
env -u RUSTFLAGS cargo test --no-fail-fast 2>&1 | tee "$LOG" || rc=$?

# Aggregate every libtest "test result: ..." summary line (unit + integration + doctests).
read -r passed failed skipped < <(awk '
  /^test result:/ {
    for (i = 1; i <= NF; i++) {
      if ($(i+1) == "passed;")  p += $i
      if ($(i+1) == "failed;")  f += $i
      if ($(i+1) == "ignored;") s += $i
    }
  }
  END { printf "%d %d %d\n", p, f, s }
' "$LOG")
rm -f "$LOG"

# A cargo/compile failure (rc!=0) with no parsed tests must FAIL loudly — the runner should
# have been built by build.sh.
if [ "$rc" -ne 0 ] && [ "$((passed + failed))" -eq 0 ]; then
  echo "ERROR: cargo test produced no results (rc=$rc) — build.sh should have compiled the suite" >&2
  emit_ctrf "cargo-test" 0 1 0
  exit 1
fi

emit_ctrf "cargo-test" "$passed" "$failed" "$skipped"
