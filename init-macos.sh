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
LOCAL_PREFIX="$HOME/.local"
LOCAL_BIN="$LOCAL_PREFIX/bin"
LOCAL_OPT="$LOCAL_PREFIX/opt"
mkdir -p "$LOCAL_BIN" "$LOCAL_OPT"
# Make tools installed by this script available immediately, without requiring
# a new shell. This also keeps everything in the user's home directory.
export PATH="$LOCAL_BIN:/usr/local/bin:$PATH"

# ---- native macOS tools (no Homebrew) ----
# These installers use official upstream releases and are safe to re-run. The
# architecture is deliberately x86_64: this machine is an Intel Mac.
github_latest_tag() {
  local repo="$1" url
  url="$(curl -fsSL -o /dev/null -w '%{url_effective}' \
    "https://github.com/$repo/releases/latest")"
  printf '%s\n' "${url##*/}"
}

install_kitty() {
  if command -v kitty >/dev/null 2>&1; then
    return
  elif [[ -x "/Applications/kitty.app/bin/kitty" ]]; then
    ln -sfn "/Applications/kitty.app/bin/kitty" "$LOCAL_BIN/kitty"
    return
  elif [[ ! -x "$LOCAL_OPT/kitty.app/bin/kitty" ]]; then
    curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh |
      /bin/sh -s -- "dest=$LOCAL_OPT" launch=n
  fi
  ln -sfn "$LOCAL_OPT/kitty.app/bin/kitty" "$LOCAL_BIN/kitty"
}

install_cmake() {
  command -v cmake >/dev/null 2>&1 && return
  local version dmg mount
  version="$(github_latest_tag Kitware/CMake)"
  dmg="$(mktemp -t cmake).dmg"
  mount="$(mktemp -d)"
  curl -fsSL -o "$dmg" \
    "https://github.com/Kitware/CMake/releases/latest/download/cmake-${version#v}-macos-universal.dmg"
  hdiutil attach -nobrowse -readonly -mountpoint "$mount" "$dmg" >/dev/null
  rm -rf "$LOCAL_OPT/CMake.app"
  cp -R "$mount/CMake.app" "$LOCAL_OPT/CMake.app"
  hdiutil detach "$mount" >/dev/null
  rm -rf "$dmg" "$mount"
  for tool in cmake cpack ctest; do
    ln -sfn "$LOCAL_OPT/CMake.app/Contents/bin/$tool" "$LOCAL_BIN/$tool"
  done
}

install_fastfetch() {
  command -v fastfetch >/dev/null 2>&1 && return
  local tmp="${TMPDIR:-/tmp}/fastfetch-$$"
  rm -rf "$tmp"; mkdir -p "$tmp"
  curl -fsSL \
    https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-macos-amd64.tar.gz |
    tar -xzf - -C "$tmp"
  cp -R "$tmp"/*/usr/. "$LOCAL_PREFIX/"
  rm -rf "$tmp"
}

install_helix() {
  command -v hx >/dev/null 2>&1 && return
  local version archive tmp extracted
  version="$(github_latest_tag helix-editor/helix)"
  archive="$(mktemp -t helix).tar.xz"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$archive" \
    "https://github.com/helix-editor/helix/releases/download/$version/helix-$version-x86_64-macos.tar.xz"
  tar -xJf "$archive" -C "$tmp"
  extracted="$tmp/helix-$version-x86_64-macos"
  rm -rf "$LOCAL_OPT/helix"
  mv "$extracted" "$LOCAL_OPT/helix"
  ln -sfn "$LOCAL_OPT/helix/hx" "$LOCAL_BIN/hx"
  ln -sfn "$LOCAL_OPT/helix/hx" "$LOCAL_BIN/helix"
  rm -rf "$archive" "$tmp"
}

install_carapace() {
  command -v carapace >/dev/null 2>&1 && return
  local version archive tmp
  version="$(github_latest_tag carapace-sh/carapace-bin)"
  version="${version#v}"
  archive="$(mktemp -t carapace).tar.gz"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$archive" \
    "https://github.com/carapace-sh/carapace-bin/releases/latest/download/carapace-bin_${version}_darwin_amd64.tar.gz"
  tar -xzf "$archive" -C "$tmp"
  install -m 755 "$tmp/carapace" "$LOCAL_BIN/carapace"
  rm -rf "$archive" "$tmp"
}

install_gram() {
  command -v gram >/dev/null 2>&1 && return
  curl -fsSL -o "$LOCAL_BIN/gram" \
    https://github.com/Jeadie/gram/releases/latest/download/gram-darwin-amd64
  chmod 755 "$LOCAL_BIN/gram"
}

install_gh() {
  command -v gh >/dev/null 2>&1 && return
  local version archive tmp
  version="$(github_latest_tag cli/cli)"
  version="${version#v}"
  archive="$(mktemp -t gh).zip"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$archive" \
    "https://github.com/cli/cli/releases/download/v$version/gh_${version}_macOS_amd64.zip"
  unzip -q "$archive" -d "$tmp"
  install -m 755 "$tmp/gh_${version}_macOS_amd64/bin/gh" "$LOCAL_BIN/gh"
  rm -rf "$archive" "$tmp"
}

install_node() {
  command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1 && return
  local line version archive tmp node_dir
  # Read the official checksum manifest to discover the current Node 22
  # x86_64 macOS archive without depending on Python, jq, or Homebrew.
  while read -r _ line; do
    case "$line" in
      node-v22.*-darwin-x64.tar.gz) version="$line"; break ;;
    esac
  done < <(curl -fsSL https://nodejs.org/dist/latest-v22.x/SHASUMS256.txt)
  [[ -n "${version:-}" ]] || { echo "Could not find the Node.js macOS x64 archive" >&2; exit 1; }
  archive="$(mktemp -t node).tar.gz"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$archive" "https://nodejs.org/dist/latest-v22.x/$version"
  tar -xzf "$archive" -C "$tmp"
  node_dir="${version%.tar.gz}"
  rm -rf "$LOCAL_OPT/node"
  mv "$tmp/$node_dir" "$LOCAL_OPT/node"
  ln -sfn "$LOCAL_OPT/node/bin/node" "$LOCAL_BIN/node"
  ln -sfn "$LOCAL_OPT/node/bin/npm" "$LOCAL_BIN/npm"
  ln -sfn "$LOCAL_OPT/node/bin/npx" "$LOCAL_BIN/npx"
  rm -rf "$archive" "$tmp"
}

install_bash_language_server() {
  command -v bash-language-server >/dev/null 2>&1 && return
  install_node
  npm install --global --prefix "$LOCAL_PREFIX" bash-language-server
}

install_font() {
  compgen -G "$HOME/Library/Fonts/*JetBrainsMonoNerdFont*.ttf" >/dev/null && return
  local archive tmp
  archive="$(mktemp -t JetBrainsMono).zip"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$archive" \
    https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
  unzip -q "$archive" -d "$tmp"
  mkdir -p "$HOME/Library/Fonts"
  for font in "$tmp"/*NerdFont*.ttf; do
    [[ -f "$font" ]] && cp "$font" "$HOME/Library/Fonts/"
  done
  rm -rf "$archive" "$tmp"
}

install_kanata() {
  # Deliberately NOT installed via cargo-binstall. binstall resolves versions
  # from crates.io, which lags upstream and still publishes 1.11.0 as stable —
  # but kanata/config.kbd requires the 1.12.0 `tap-hold-require-prior-idle`
  # defcfg option. binstall therefore pins us to a version that cannot parse
  # the config, and kanata exits 1 on startup while launchd KeepAlive restarts
  # it every 10s forever. Pull the GitHub release asset instead, and re-check
  # every run so the upgrade actually lands on an existing install.
  local tag version archive sums expected actual tmp
  tag="$(github_latest_tag jtroo/kanata)"
  version="${tag#v}"

  # Idempotent: no-op when the installed version already matches upstream.
  if command -v kanata >/dev/null 2>&1 &&
    [[ "$(kanata --version 2>/dev/null)" == "kanata $version" ]]; then
    return
  fi

  tmp="$(mktemp -d)"
  archive="$tmp/kanata.zip"
  sums="$tmp/sha256sums"
  curl -fsSL -o "$archive" \
    "https://github.com/jtroo/kanata/releases/download/$tag/macos-binaries-x64.zip"
  curl -fsSL -o "$sums" \
    "https://github.com/jtroo/kanata/releases/download/$tag/sha256sums"

  expected="$(awk '$2 == "macos-binaries-x64.zip" { print $1 }' "$sums")"
  actual="$(shasum -a 256 "$archive" | awk '{ print $1 }')"
  if [[ -z "$expected" || "$expected" != "$actual" ]]; then
    echo "kanata: checksum mismatch for $tag ($expected != $actual)" >&2
    rm -rf "$tmp"
    exit 1
  fi

  unzip -oq "$archive" -d "$tmp"
  # kanata.plist hardcodes ~/.cargo/bin/kanata, so keep that exact path.
  # kanata_macos_x64 is the default build (cmd actions compiled out); the
  # config only uses Ctrl/Shift, so the _cmd_allowed variant is not needed.
  mkdir -p "$HOME/.cargo/bin"
  install -m 755 "$tmp/kanata_macos_x64" "$HOME/.cargo/bin/kanata"
  rm -rf "$tmp"
}

install_kitty
install_cmake
install_fastfetch
install_helix
install_carapace
install_bash_language_server
install_gram
install_gh
install_font

# ---- rust toolchain (rustup) ----
if ! command -v rustup >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
# rustup only edits login-shell RC files; expose ~/.cargo/bin in this script
# (also fixes `cargo binstall` below and `which nu` at the end).
# shellcheck disable=SC1091
source "$HOME/.cargo/env"

# Update the Rust toolchain (matches nixpkgs-unstable on NixOS; a no-op on a
# fresh install, and keeps stale toolchains fresh on re-runs).
rustup update stable

# ---- Rust CLI tools via cargo-binstall (prebuilt binaries when available;
#      auto-falls back to `cargo install` when none exist) ----
# Mirrors the rust-toolchain block in nixos/home.nix. Only missing commands are
# passed to binstall; existing tools are left alone to avoid needless downloads.
if ! command -v cargo-binstall >/dev/null 2>&1; then
  cargo install cargo-binstall
fi

cargo_packages=()
while IFS=: read -r package binary; do
  command -v "$binary" >/dev/null 2>&1 || cargo_packages+=("$package")
done <<'TOOLS'
nu:nu
starship:starship
zellij:zellij
bat:bat
eza:eza
ripgrep:rg
fd-find:fd
zoxide:zoxide
atuin:atuin
topgrade:topgrade
yazi-fm:yazi
cargo-expand:cargo-expand
cargo-update:cargo-install-update
sccache:sccache
git-delta:delta
skim:sk
rtk:rtk
TOOLS

if ((${#cargo_packages[@]})); then
  cargo binstall -y "${cargo_packages[@]}"
fi

# Tools with non-standard release naming (leaf, presenterm) live in their own
# script so NixOS installs the exact same list — see init-cargo-tools.sh.
"$DOTFILES/init-cargo-tools.sh"

# kanata comes from a GitHub release asset, not binstall — see install_kanata.
install_kanata

# ---- nushell: use the repo's my.nu as the real config ----
# On macOS (XDG_CONFIG_HOME unset) nu reads config from
# ~/Library/Application Support/nushell, NOT ~/.config — resolve the real
# directory via nu itself. Mirrors home.nix:117-118 on NixOS.
NU_CONFIG_DIR="$(nu --no-config-file -c '$nu.default-config-dir')"
mkdir -p "$NU_CONFIG_DIR" "$HOME/Library/Caches/nushell"
printf 'source %s/nushell/my.nu\n' "$DOTFILES" > "$NU_CONFIG_DIR/config.nu"
: > "$NU_CONFIG_DIR/env.nu"

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

# ---- pi-coding-agent ----
if ! command -v pi >/dev/null 2>&1; then
  curl -fsSL https://pi.dev/install.sh | sh
fi
# Keep pi discoverable from Nushell even when the installer used a versioned
# standalone Node directory for npm's global prefix.
if PI_BIN="$(command -v pi 2>/dev/null)"; then
  ln -sfn "$PI_BIN" "$LOCAL_BIN/pi"
fi

# ---- global AI-tool rules: repo AGENTS.md is the single source of truth ----
ln -sfn "$DOTFILES/AGENTS.md" "$HOME/AGENTS.md"
mkdir -p "$HOME/.pi/agent" "$HOME/.claude" "$HOME/.codex"
ln -sfn "$DOTFILES/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"
ln -sfn "$DOTFILES/AGENTS.md" "$HOME/.claude/CLAUDE.md"
ln -sfn "$DOTFILES/AGENTS.md" "$HOME/.codex/AGENTS.md"

# ---- pi global agent config (repo is the source of truth). Runtime state
#      (sessions, npm/git packages, auth.json, tmp) stays unmanaged. ----
ln -sfn "$DOTFILES/pi/settings.json" "$HOME/.pi/agent/settings.json"
ln -sfn "$DOTFILES/pi/pi-beautiful-tui.json" "$HOME/.pi/agent/pi-beautiful-tui.json"
# -sfn would nest a symlink inside an existing real dir; drop it first so the
# repo dir wins (rm on a symlink removes only the link).
rm -rf "$HOME/.pi/agent/agents" "$HOME/.pi/agent/extensions"
ln -sfn "$DOTFILES/pi/agents" "$HOME/.pi/agent/agents"
ln -sfn "$DOTFILES/pi/extensions" "$HOME/.pi/agent/extensions"

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
