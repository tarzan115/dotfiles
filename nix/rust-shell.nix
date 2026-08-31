# Rust dev shell definition. Lives here so dotfiles stays the single
# source of truth; workspace flakes import it via a path input, so edits
# to this file take effect on the next `nix develop` run.
{ pkgs }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Rust toolchain
    cargo
    rustc
    rustfmt
    clippy
    rust-analyzer
    cargo-expand

    # Build dependencies
    pkg-config
    openssl

    # Useful utilities
    git
    curl
    nushell
  ];

  # nix develop always launches bashInteractive and runs this hook there;
  # exec nu hands off to nushell once the environment is set up.
  shellHook = ''
    echo "Rust development environment loaded"
    echo "Cargo: $(cargo --version)"
    echo "Rustc: $(rustc --version)"
    echo "LIVE-EDIT-TEST"
    exec nu
  '';
}