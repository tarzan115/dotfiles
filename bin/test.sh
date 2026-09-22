#!/usr/bin/env bash
# Smoke checks for the bin/ wrappers' flag translation. Run: bash bin/test.sh
set -u
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" || exit 1

tmp=$(mktemp -d) && trap 'rm -rf "$tmp"' EXIT
printf 'alpha\nbeta\n' >"$tmp/f1"
printf 'gamma\n' >"$tmp/f2"

has() { # has NAME NEEDLE HAYSTACK
    case "$3" in
        *"$2"*) echo "ok $1" ;;
        *) echo "FAIL $1: missing '$2' in -> $3"; exit 1 ;;
    esac
}
no() { # no NAME NEEDLE HAYSTACK
    case "$3" in
        *"$2"*) echo "FAIL $1: found '$2' in -> $3"; exit 1 ;;
        *) echo "ok $1" ;;
    esac
}

# -h = no filenames (must NOT hit rg's help)
out=$(./grep -h alpha "$tmp/f1" "$tmp/f2")
has "grep -h" "alpha" "$out"
no "grep -h (no help)" "Usage" "$out"
no "grep -h (no filename)" "f1" "$out"

out=$(./grep -rh gamma "$tmp")
has "grep -rh" "gamma" "$out"
no "grep -rh (no help)" "Usage" "$out"

out=$(./grep -vi alpha "$tmp/f1")
has "grep -vi" "beta" "$out"

# untranslatable flag -> real grep fallback, must still work
out=$(./grep -A1 alpha "$tmp/f1")
has "grep -A1 fallback" "beta" "$out"

echo PASS
