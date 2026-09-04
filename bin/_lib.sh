#!/usr/bin/env bash
# _lib.sh — shared helpers for the modern-tool wrappers.
# Sourced by each wrapper in bin/. Resolves the ORIGINAL POSIX tool by scanning
# PATH while skipping this wrapper's own directory.

_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# resolve through symlinks to find a path's real location (few levels are enough)
_resolve() {
    local p="$1" t
    while [[ -L "$p" ]]; do
        t="$(readlink "$p")"
        case "$t" in
            /*) p="$t" ;;
            *) p="$(dirname "$p")/$t" ;;
        esac
    done
    printf '%s\n' "$p"
}

# orig_path NAME — print the path of the first executable NAME on PATH that is
# not one of our wrappers (i.e. not in _LIB_DIR, following symlinks).
orig_path() {
    local name="$1" dir IFS=: resolved
    for dir in $PATH; do
        [[ -n "$dir" ]] || continue
        [[ -x "$dir/$name" && ! -d "$dir/$name" ]] || continue
        resolved="$(_resolve "$dir/$name")"
        # skip our own wrappers (matches real repo path or the symlink dir)
        [[ "$resolved" == "$_LIB_DIR/$name" ]] && continue
        printf '%s\n' "$dir/$name"
        return 0
    done
    return 1
}

# run_orig NAME [args...] — exec the original tool with the given args.
run_orig() {
    local name="$1"
    shift
    local path
    path="$(orig_path "$name")" || {
        printf '%s: original %s not found on PATH\n' "$0" "$name" >&2
        return 127
    }
    exec "$path" "$@"
}

# has_modern NAME — true if the modern tool is installed.
has_modern() {
    command -v "$1" >/dev/null 2>&1
}