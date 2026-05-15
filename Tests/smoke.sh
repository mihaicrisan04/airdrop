#!/bin/sh
# smoke tests for the airdrop binary.
# verifies argument handling without invoking AirDrop (that needs a real device).

BIN="${1:-build/Airdrop.app/Contents/MacOS/airdrop}"

if [ ! -x "$BIN" ]; then
    echo "FAIL: binary not found or not executable at $BIN"
    exit 1
fi

fail=0

run_check() {
    desc="$1"
    expected_rc="$2"
    shift 2
    "$@" >/dev/null 2>&1
    actual_rc=$?
    if [ "$actual_rc" -eq "$expected_rc" ]; then
        echo "  pass: $desc (exit $actual_rc)"
    else
        echo "  FAIL: $desc (expected $expected_rc, got $actual_rc)"
        fail=$((fail + 1))
    fi
}

assert_grep() {
    desc="$1"
    pattern="$2"
    shift 2
    out=$("$@" 2>&1)
    if echo "$out" | grep -qE "$pattern"; then
        echo "  pass: $desc"
    else
        echo "  FAIL: $desc (output did not match /$pattern/)"
        fail=$((fail + 1))
    fi
}

echo "running smoke tests against $BIN"

run_check "--help exits 0"        0 "$BIN" --help
run_check "-h exits 0"            0 "$BIN" -h
run_check "--version exits 0"     0 "$BIN" --version
run_check "-V exits 0"            0 "$BIN" -V
run_check "no args exits 2"       2 "$BIN"
run_check "unknown flag exits 2"  2 "$BIN" --bogus
run_check "missing file exits 1"  1 "$BIN" /no/such/file

assert_grep "--help mentions usage" "usage:"                    "$BIN" --help
assert_grep "--version is semver"   "^ad [0-9]+\.[0-9]+\.[0-9]+" "$BIN" --version

echo
if [ "$fail" -eq 0 ]; then
    echo "all tests passed"
    exit 0
else
    echo "$fail test(s) failed"
    exit 1
fi
