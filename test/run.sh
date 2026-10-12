#!/usr/bin/env bash
# Run the plugin through fnox against a static mock of the example API.
# Requires fnox (with Lua plugin support) and python3 on PATH.
set -euo pipefail

cd "$(dirname "$0")"
FNOX="${FNOX:-fnox}"
PORT=18765
export FNOX_CONFIG_FILE="$PWD/fnox.toml"

python3 -m http.server "$PORT" --bind 127.0.0.1 --directory fixtures >/dev/null 2>&1 &
server=$!
trap 'kill "$server" 2>/dev/null || true' EXIT
for _ in $(seq 50); do
	if (exec 3<>"/dev/tcp/127.0.0.1/$PORT") 2>/dev/null; then break; fi
	sleep 0.1
done

failures=0
pass() { echo "ok - $1"; }
fail() {
	echo "not ok - $1"
	failures=$((failures + 1))
}

if [ "$(EXAMPLE_TOKEN=test "$FNOX" get DATABASE_URL)" = "postgres://app@db.internal/app" ]; then
	pass "get returns the secret value"
else
	fail "get returns the secret value"
fi

if out=$(EXAMPLE_TOKEN=test "$FNOX" get MISSING 2>&1); then
	fail "missing secret is reported as not found"
elif grep -q "not found" <<<"$out"; then
	pass "missing secret is reported as not found"
else
	fail "missing secret is reported as not found: $out"
fi

if out=$(env -u EXAMPLE_TOKEN FNOX_PROMPT_AUTH=false "$FNOX" get DATABASE_URL 2>&1); then
	fail "missing token is an authentication error"
elif grep -q "authentication failed" <<<"$out"; then
	pass "missing token is an authentication error"
else
	fail "missing token is an authentication error: $out"
fi

if EXAMPLE_TOKEN=test "$FNOX" provider test example >/dev/null; then
	pass "provider test succeeds"
else
	fail "provider test succeeds"
fi

exit "$failures"
