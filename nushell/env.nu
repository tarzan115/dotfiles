$env.config.buffer_editor = "zed"
$env.config.show_banner = false
$env.EDITOR = "hx"
$env.SHELL = $"($nu.home-dir)/.cargo/bin/nu"

source $"($nu.home-dir)/.cargo/env.nu"

# $env.PATH = $env.PATH + ":~/.local/bin"
$env.Path = ($env.Path | prepend '~/.local/bin')
$env.Path = ($env.Path | prepend '~/Documents/RustRover-2026.1.1/bin')
$env.Path = ($env.Path | prepend '~/.opencode/bin')

source ~/.zoxide.nu

$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
mkdir $"($nu.cache-dir)"
carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu"
