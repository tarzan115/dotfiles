$env.config.buffer_editor = "gram"
$env.config.show_banner = false
$env.EDITOR = "hx"

if $nu.os-info.name == "macos" {
    # Homebrew nushell; use the absolute path of the running shell ($SHELL is
    # expected to be an absolute path by programs that exec it).
    $env.SHELL = $nu.current-exe
    $env.Path = ($env.Path | prepend '~/.cargo/bin')
    $env.Path = ($env.Path | prepend '/opt/homebrew/bin')
} else if $nu.os-info.name == "windows" {
    $env.Path = ($env.Path | prepend '~/.cargo/bin')
} else {
    # NixOS: nushell is the login shell (users.users.doanh.shell in
    # configuration.nix) and lives in the system profile. home.nix also
    # provides a ~/.cargo/bin/nu shim for scripts that hardcode that path.
    # $nu.current-exe keeps $SHELL an absolute path.
    $env.SHELL = $nu.current-exe
    $env.Path = ($env.Path | prepend '/opt/adguardvpn_cli')
}

$env.Path = ($env.Path | prepend '~/.local/bin')
$env.Path = ($env.Path | prepend '~/.opencode/bin')

source ~/.zoxide.nu
source ~/.atuin.nu

$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
