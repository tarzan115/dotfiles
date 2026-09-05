# Global Agent Rules — Modern CLI Tools

When running shell commands, prefer modern replacements over classic POSIX tools.
This file becomes the global ruleset for most AI CLIs, and `~/.local/bin`
contains PATH wrappers (`grep`→`rg`, `find`→`fd`, `cat`→`bat`, `ls`→`eza`) so
even the legacy spellings resolve to the modern tools — with automatic fallback
to the original when flags don't overlap.

## Tool map

| Classic (avoid)              | Modern (prefer)          | Notes |
| ---------------------------- | ------------------------ | ----- |
| `grep`, `egrep`, `grep -r`   | `rg`                     | Recursive by default; respects `.gitignore`; use `-uu` to include ignored/hidden files |
| `find`                       | `fd`                     | Respects `.gitignore`; hidden files only with `--hidden`; flags: `--type`, `--extension`, `--max-depth`, `--glob` |
| `cat`                        | `bat`                    | Use `bat -p` (or the `cat` wrapper) for plain, raw output |
| `ls`, `ls -la`, `tree`       | `eza`                    | `eza --tree --level=N` replaces `tree`; `eza -lah` replaces `ls -lah` |
| `cd` history (repeated paths) | `z` / `zoxide`          | `z <fragment>` jumps to a known directory |
| `less` / paging files        | `bat --paging=always`    | Keep paging off unless explicitly asked |
| `which`                      | `command -v`             | Avoid: `which` can return non-executable aliases in some shells |
| fuzzy text selection         | `sk` (skim)              | Use for pickers/choosers |
| visual file browsing         | `yazi`                   | TUI file manager |

## Rules

1. Default to `rg`/`fd`/`bat`/`eza` everywhere — they are installed and skip
   `.gitignore`d and binary files by default.
2. For file search inside a codebase, prefer the editor/agent's dedicated
   search tools when available (they are faster and indexed); fall back to
   `rg`/`fd` in the shell only when needed.
3. Searching intentionally ignored or hidden files:
   - `rg -uu <pattern>` includes ignored and hidden files.
   - `fd --hidden` includes hidden entries.
4. Keep outputs raw and unbounded for the agent: don't pipe through pagers,
   don't truncate results, and don't rely on TTY color/columns (output is
   captured).
5. When the modern tool cannot express the operation (e.g. `grep` BRE
   backreferences, `find -exec`, complex `sed` scripts), use the original tool
   by its real path or keep the classic tool name — the wrappers fall back
   automatically for known incompatible flags.
6. Never write files via `cat <<EOF`; use the editor's write tool. Never use
   `grep`/`sed`/`awk` to parse JSON — prefer a real parser.