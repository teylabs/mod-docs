#!/usr/bin/env bash
set -euo pipefail
VERIFY=$(cd "$(dirname "$0")" && pwd)
DOCS=$(cd "$VERIFY/.." && pwd)
if [ "$#" -lt 2 ]; then
    echo 'Usage: verify/run.sh <workdir> <12|13> [...] [-- <scenario> ...]' >&2
    exit 1
fi
WORK=$(cd "$1" && pwd); shift
majors=(); scenarios=()
while [ "$#" -gt 0 ] && [ "$1" != -- ]; do
    case $1 in 12|13) majors+=("$1");; *) echo "Unsupported Laravel version: $1" >&2; exit 1;; esac
    shift
done
if [ "$#" -gt 0 ]; then shift; scenarios=("$@"); fi
if [ "${#scenarios[@]}" -eq 0 ]; then
    scenarios=(quick-start layouts generating-files auto-discovery custom-layouts stubs self-contained-modules plugins custom-generators scaffolds upgrade introduction commands layout-api configuration)
fi
[ "${#majors[@]}" -gt 0 ]
test -f "$WORK/.mod-docs-harness"
for scenario in "${scenarios[@]}"; do
    case $scenario in quick-start|layouts|generating-files|auto-discovery|custom-layouts|stubs|self-contained-modules|plugins|custom-generators|scaffolds|upgrade|introduction|commands|layout-api|configuration) ;; *) echo "Unknown scenario: $scenario" >&2; exit 1;; esac
done
source "$VERIFY/lib.sh"
PASS=0; FAIL=0
LOG=$WORK/verify.txt; : > "$LOG"
for MAJOR in "${majors[@]}"; do
    APP=$WORK/base-$MAJOR
    test -f "$APP/artisan"
    for SCENARIO in "${scenarios[@]}"; do
        # A fixture error must fail the run, never fall through to a later check.
        set +e
        (set -e; source "$VERIFY/scenarios/$SCENARIO.sh") > "$WORK/scenario-output.txt" 2>&1
        scenario_exit=$?
        set -e
        cat "$WORK/scenario-output.txt"
        if [ "$scenario_exit" -ne 0 ]; then
            # Each scenario records checks in its own subshell.
            record FAIL 'Scenario could not finish its fixture setup'
        fi
    done
done
PASS=$(grep -c '^PASS |' "$LOG" || true)
FAIL=$(grep -c '^FAIL |' "$LOG" || true)
printf '%s passed, %s failed\n' "$PASS" "$FAIL" | tee -a "$LOG"
[ "$FAIL" -eq 0 ]
