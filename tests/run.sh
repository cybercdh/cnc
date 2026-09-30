#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
mkdir -p tmp

fail=0
total=0

while IFS='|' read -r name args || [[ -n "${name:-}" ]]; do
  # Skip blanks and comments
  [[ -z "${name// }" ]] && continue
  [[ "${name:0:1}" == "#" ]] && continue

  total=$((total+1))
  infile="${name}.in"
  outfile="${name}.out"
  actual="tmp/${name}.actual"
  diffout="tmp/${name}.diff"

  if [[ "$name" == *_stdin ]]; then
    base="${name%_stdin}"
    infile="${base}.in"
    # Reuse base expected output unless specific exists
    [[ -f "${name}.out" ]] && outfile="${name}.out" || outfile="${base}.out"
    if ! cat "$infile" | ../cnc $args - > "$actual" 2> "${actual}.err"; then
      echo "[FAIL] $name: command failed"
      fail=$((fail+1))
      continue
    fi
  else
    if ! ../cnc $args "$infile" > "$actual" 2> "${actual}.err"; then
      echo "[FAIL] $name: command failed"
      fail=$((fail+1))
      continue
    fi
  fi

  if diff -u "$outfile" "$actual" > "$diffout" 2>&1; then
    echo "✓ $name"
  else
    echo "[FAIL] $name: output mismatch"
    sed -n '1,200p' "$diffout"
    fail=$((fail+1))
  fi
done < ./manifest

# Expected-failure cases: an empty pattern set must error, not silently cat.
total=$((total+1))
if printf 'a\n# b\n' | ../cnc -c ',' >/dev/null 2>&1; then
  echo "[FAIL] empty_pattern_guard: expected non-zero exit"
  fail=$((fail+1))
else
  echo "✓ empty_pattern_guard"
fi

if (( fail > 0 )); then
  echo "${fail}/${total} tests failed"
  exit 1
else
  echo "All ${total} tests passed"
fi

