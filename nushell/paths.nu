# PATH is kept separate from env.nu so package locations are easy to audit.
if $nu.os-info.name == "macos" {
    # Pi's standalone installer keeps Node and pi under a versioned directory.
    # Include every installed version so upgrading Node does not break `pi`.
    let pi_node_bins = (glob ($nu.home-dir | path join '.local' 'share' 'pi-node' '*' 'bin'))
    $env.Path = ($env.Path | prepend $pi_node_bins)
    $env.Path = ($env.Path | prepend ($nu.home-dir | path join '.pi' 'agent' 'bin'))
} else {
    # NixOS: nushell is the login shell and the system profile supplies its
    # binaries. Keep the extra local paths here, not in env.nu.
    $env.Path = ($env.Path | prepend '/opt/adguardvpn_cli')
}

# cargo-binstall tools (leaf, presenterm, ...) land here on every OS.
$env.Path = ($env.Path | prepend '~/.cargo/bin')
$env.Path = ($env.Path | prepend '~/.local/bin')
