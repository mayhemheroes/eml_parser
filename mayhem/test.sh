#!/usr/bin/env bash
set -uo pipefail
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH
cd "$SRC"

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

if [ ! -x /mayhem/test-venv/bin/python ]; then
  echo "missing /mayhem/test-venv — build.sh should have built the oracle venv" >&2
  emit_ctrf "pytest" 0 1 0
  exit 1
fi

out="$(/mayhem/test-venv/bin/python -m pytest -q -p no:sugar tests/ 2>&1)"
echo "$out"

summary="$(printf '%s\n' "$out" | grep -E '^[0-9]+ (passed|failed)|passed|failed|error' | tail -1)"

passed=$(printf '%s\n' "$summary" | grep -oE '[0-9]+ passed'  | grep -oE '[0-9]+' || echo 0)
failed=$(printf '%s\n' "$summary" | grep -oE '[0-9]+ failed'  | grep -oE '[0-9]+' || echo 0)
errors=$(printf '%s\n' "$summary" | grep -oE '[0-9]+ error'   | grep -oE '[0-9]+' || echo 0)
skipped=$(printf '%s\n' "$summary" | grep -oE '[0-9]+ skipped'| grep -oE '[0-9]+' || echo 0)

passed=${passed:-0}; failed=${failed:-0}; errors=${errors:-0}; skipped=${skipped:-0}
failed=$(( failed + errors ))

emit_ctrf "pytest" "$passed" "$failed" "$skipped"
