$env.config.buffer_editor = "gram"
$env.config.show_banner = false
$env.EDITOR = "hx"

if $nu.os-info.name == "macos" {
    $env.SHELL = ((which nu).path | first)
    $env.Path = ($env.Path | prepend '~/.cargo/bin')
    $env.Path = ($env.Path | prepend '/opt/homebrew/bin')
    } else {
    $env.SHELL = $"($nu.home-dir)/.cargo/bin/nu"
    $env.Path = ($env.Path | prepend '/opt/adguardvpn_cli')
}

$env.Path = ($env.Path | prepend '~/.local/bin')
$env.Path = ($env.Path | prepend '~/.opencode/bin')

source ~/.zoxide.nu
source ~/.atuin.nu

$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
