$env.config.buffer_editor = "zed"
$env.config.show_banner = false
source $"($nu.home-dir)/.cargo/env.nu"

# $env.PATH = $env.PATH + ":~/.local/bin"
$env.Path = ($env.Path | prepend '~/.local/bin')
source ~/.zoxide.nu
