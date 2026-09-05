#!/usr/bin/env bash
# macOS bootstrap: installs tools and wires up the dotfiles.
# NixOS is configured declaratively via home.nix — this is NOT used for NixOS
# installs (nixos-install --flake ~/dotfiles/nixos handles everything there).
set -euo pipefail

# Verbose tracing: log each command before running it so we can see where it fails.
PS4='+ [${BASH_SOURCE}:${LINENO}] '
set -x

# On any error, report exactly which line failed before exiting.
trap 'rc=$?; echo "[init-macos] ERROR: command failed with exit code $rc at line $LINENO" >&2' ERR

# macOS-only guard
case "$(uname -s)" in
  Darwin) ;;
  *)
    echo "Error: init-macos.sh can only run on macOS (current OS: $(uname -s))" >&2
    exit 1
    ;;
esac

DOTFILES="$HOME/dotfiles"
CONFIG_DIR="$HOME/.config"

# ---- Homebrew ----
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# ---- tools ----
brew install nushell starship zellij kitty helix fzf cmake bash-language-server \
  carapace fastfetch bat eza ripgrep fd zoxide atuin topgrade yazi \
  cargo-binstall cargo-expand cargo-update sccache git-delta

brew install --cask font-jetbrains-mono-nerd-font gram

# ---- rust + kanata ----
if ! command -v rustup >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
cargo binstall -y kanata

# ---- nushell: use the repo's my.nu as the real config ----
mkdir -p "$CONFIG_DIR/nushell"
printf 'source %s/nushell/my.nu\n' "$DOTFILES" > "$CONFIG_DIR/nushell/config.nu"
: > "$CONFIG_DIR/nushell/env.nu"

# generated init files (guarded by config.nu/env.nu, so a missing one won't break startup)
starship init nu | nu --no-config-file --stdin -c 'save -f ($nu.home-dir | path join ".config" "starship.nu")'
carapace _carapace nushell | nu --no-config-file --stdin -c 'save -f ($nu.cache-dir | path join "carapace.nu")'
zoxide init nushell | nu --no-config-file --stdin -c 'save -f ($nu.home-dir | path join ".zoxide.nu")'
atuin init nu | nu --no-config-file --stdin -c 'save -f ($nu.home-dir | path join ".atuin.nu")'

# ---- dotfiles: symlink configs so the repo stays the source of truth ----
ln -sfn "$DOTFILES/kitty/kitty.conf" "$CONFIG_DIR/kitty/kitty.conf"
ln -sfn "$DOTFILES/helix/config.toml" "$CONFIG_DIR/helix/config.toml"
ln -sfn "$DOTFILES/helix/themes" "$CONFIG_DIR/helix/themes"
ln -sfn "$DOTFILES/starship/starship.toml" "$CONFIG_DIR/starship.toml"
ln -sfn "$DOTFILES/yazi" "$CONFIG_DIR/yazi"
ln -sfn "$DOTFILES/zellij/config.kdl" "$CONFIG_DIR/zellij/config.kdl"
ln -sfn "$DOTFILES/cargo/config.toml" "$HOME/.cargo/config.toml"

# ---- global AI-tool rules: repo AGENTS.md is the single source of truth ----
ln -sfn "$DOTFILES/AGENTS.md" "$HOME/AGENTS.md"
mkdir -p "$CONFIG_DIR/opencode" "$HOME/.claude" "$HOME/.codex"
ln -sfn "$DOTFILES/AGENTS.md" "$CONFIG_DIR/opencode/AGENTS.md"
ln -sfn "$DOTFILES/AGENTS.md" "$HOME/.claude/CLAUDE.md"
ln -sfn "$DOTFILES/AGENTS.md" "$HOME/.codex/AGENTS.md"

# ---- modern-tool wrappers in ~/.local/bin (nu env.nu prepends it to PATH) ----
mkdir -p "$HOME/.local/bin"
for tool in grep find cat ls; do
  ln -sfn "$DOTFILES/bin/$tool" "$HOME/.local/bin/$tool"
done
# topgrade.toml is NixOS-specific (flake update/rebuild); macOS uses the auto-generated config

# ---- kanata (launchd agent; Linux uses services.kanata on NixOS) ----
mkdir -p "$CONFIG_DIR/kanata" "$HOME/Library/LaunchAgents"
cp "$DOTFILES/kanata/config.kbd" "$CONFIG_DIR/kanata/config.kbd"
cp "$DOTFILES/kanata/kanata.plist" "$HOME/Library/LaunchAgents/com.doanh.kanata.plist"
launchctl load -w "$HOME/Library/LaunchAgents/com.doanh.kanata.plist"

# ---- git ----
git config --global user.email "doanhlv@duck.com"
git config --global user.name "Doanh Van Luong"
git config --global core.pager delta
git config --global interactive.diffFilter 'delta --color-only'
git config --global delta.navigate true
git config --global merge.conflictStyle zdiff3
git config --global delta.line-numbers true
git config --global delta.side-by-side true

# ---- set nushell as the login shell ----
echo "$(which nu)" | sudo tee -a /etc/shells >/dev/null
chsh -s "$(which nu)"