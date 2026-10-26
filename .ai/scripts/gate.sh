#!/usr/bin/env bash
#
# Runs the project's quality checks and prints a compact summary for agents.
# Full output of each check is saved to .ai/work/.gate/<check>.log.
#
# Usage:
#   .ai/scripts/gate.sh quick   Pint (changed files), Larastan, Pest
#   .ai/scripts/gate.sh full    Everything in quick plus Pint (all files), JS lint/format, TypeScript
#
# Exit code: 0 when every check passes, 1 otherwise.

set -uo pipefail

cd "$(dirname "$0")/../.." || exit 1

tier="${1:-full}"
log_dir=".ai/work/.gate"
failed=0

mkdir -p "$log_dir"

run_check() {
    local name="$1"
    shift

    if "$@" >"$log_dir/$name.log" 2>&1; then
        echo "✅ $name"
    else
        echo "❌ $name (full log: $log_dir/$name.log)"
        grep -v 'PHP Startup: Unable to load dynamic library' "$log_dir/$name.log" \
            | tail -n 25 \
            | awk '{ print "   " $0 }'
        failed=1
    fi
}

case "$tier" in
    quick)
        run_check pint vendor/bin/pint --dirty --test
        ;;
    full)
        run_check pint vendor/bin/pint --test
        run_check js-lint npm run check
        run_check typescript npm run types:check
        ;;
    *)
        echo "Unknown tier: $tier (use quick or full)"
        exit 1
        ;;
esac

run_check larastan vendor/bin/phpstan analyse --no-progress
php artisan config:clear >/dev/null 2>&1
run_check pest php artisan test --compact

if [ "$failed" -eq 0 ]; then
    echo "GATE ($tier): PASSED"
else
    echo "GATE ($tier): FAILED"
fi

exit "$failed"
