$env.config.buffer_editor = "zed"
$env.config.show_banner = false
source $"($nu.home-dir)/.cargo/env.nu"

# $env.PATH = $env.PATH + ":~/.local/bin"
$env.Path = ($env.Path | prepend '~/.local/bin')
source ~/.zoxide.nu

$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
mkdir $"($nu.cache-dir)"
carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu"
