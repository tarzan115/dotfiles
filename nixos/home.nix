{
  config,
  lib,
  pkgs,
  ...
}:

let
  dotfiles = "/home/doanh/dotfiles";
  # Symlink straight to the dotfiles repo so the repo stays the single
  # source of truth (editing there is reflected live).
  link = source: config.lib.file.mkOutOfStoreSymlink source;

in
{
  home.username = "doanh";
  home.homeDirectory = "/home/doanh";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    # ---- shell / terminal ----
    nushell
    zellij
    kitty
    foot
    bat
    eza
    ripgrep
    fd
    fzf
    skim
    starship
    zoxide
    atuin
    carapace
    fastfetch
    opencode
    rumdl
    gitui

    # ---- editors ----
    helix
    gram
    bash-language-server
    libreoffice-stable

    # ---- browser ----
    firefox

    # ---- rust toolchain & cargo helpers ----
    cargo
    rustc
    rustfmt
    clippy
    rust-analyzer
    lldb
    cargo-expand
    cargo-binstall
    cargo-update
    sccache
    topgrade

    # ---- build tooling ----
    gcc
    pkg-config
    gnumake
    cmake

    # ---- yazi file manager ----
    yazi

    # ---- wayland utilities ----
    wl-clipboard
    wl-clip-persist
    cliphist
    grim
    slurp
    wf-recorder # CLI screen recorder via wlr-screencopy (no portal needed)
    kooha # portal-based screen recorder; tests the ScreenCast pipeline

    # ---- misc ----
    mangohud
  ];

  programs.git = {
    enable = true;
    settings = {
      user.name = "Doanh Van Luong";
      user.email = "doanhlv@duck.com";
      merge.conflictStyle = "zdiff3";
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      line-numbers = true;
      side-by-side = true;
      navigate = true;
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = [ "firefox.desktop" ];
    };
  };

  programs.antigravity-cli = {
    enable = true;
    defaultModel = "gemini-3.7-flash";
  };

  home.file = {
    # ---- nushell: the repo's my.nu is the real config ----
    ".config/nushell/config.nu".text = "source ${dotfiles}/nushell/my.nu\n";
    ".config/nushell/env.nu".text = "";

    # ---- kitty ----
    ".config/kitty/kitty.conf".source = link "${dotfiles}/kitty/kitty.conf";

    # ---- helix ----
    ".config/helix/config.toml".source = link "${dotfiles}/helix/config.toml";
    ".config/helix/themes".source = link "${dotfiles}/helix/themes";

    # ---- foot (mango-config submodule) ----
    ".config/foot/foot.ini".source = link "${dotfiles}/mango-config/foot/foot.ini";

    # ---- mango (whole mango-config submodule: compositor + dms fragments) ----
    ".config/mango".source = link "${dotfiles}/mango-config";

    # ---- yazi (whole dir; plugins/flavors installed with `ya pack -i`) ----
    ".config/yazi".source = link "${dotfiles}/yazi";

    # ---- topgrade ----
    ".config/topgrade.toml".source = link "${dotfiles}/topgrade.toml";

    # ---- zellij ----
    ".config/zellij/config.kdl".source = link "${dotfiles}/zellij/config.kdl";

    # ---- starship (thm theme) ----
    ".config/starship.toml".source = link "${dotfiles}/starship/starship.toml";
    ".config/starship.nu".source =
      pkgs.runCommand "starship.nu" { } ''
        ${lib.getExe pkgs.starship} init nu > "$out"
      '';

    # ---- shims so dotfiles referencing ~/.cargo keep working on NixOS ----
    ".cargo/bin/nu".source = link "${pkgs.nushell}/bin/nu";
    ".cargo/env.nu".text = "";
    ".cargo/config.toml".source = link "${dotfiles}/cargo/config.toml";

    # ---- zoxide nushell init (sourced by nushell/env.nu) ----
    ".zoxide.nu".source =
      pkgs.runCommand "zoxide-nushell.nu" { } ''
        ${lib.getExe pkgs.zoxide} init nushell > "$out"
      '';

    # ---- atuin nushell init (sourced by nushell/env.nu) ----
    ".atuin.nu".source =
      pkgs.runCommand "atuin-nushell.nu" { } ''
        HOME=$(mktemp -d) ${lib.getExe pkgs.atuin} init nu > "$out"
        # Fix duplicate keybinding names (atuin uses "atuin" for both Ctrl+R and Up)
        sed -i '137s/name: atuin/name: atuin-up/' "$out"
      '';

    # ---- global AI-tool rules: one source of truth (repo AGENTS.md),
    #      shared by every agent CLI that reads a global rules file ----
    "AGENTS.md".source = link "${dotfiles}/AGENTS.md"; # emerging home-dir convention
    ".config/opencode/AGENTS.md".source = link "${dotfiles}/AGENTS.md";
    ".claude/CLAUDE.md".source = link "${dotfiles}/AGENTS.md";
    ".codex/AGENTS.md".source = link "${dotfiles}/AGENTS.md";

    # ---- modern-tool wrappers: shadow classic names on PATH so even a
    #      plain `grep`/`find`/`cat`/`ls` lands on rg/fd/bat/eza (with
    #      automatic fallback to the original for incompatible flags) ----
    ".local/bin/grep".source = link "${dotfiles}/bin/grep";
    ".local/bin/find".source = link "${dotfiles}/bin/find";
    ".local/bin/cat".source = link "${dotfiles}/bin/cat";
    ".local/bin/ls".source = link "${dotfiles}/bin/ls";
  };

  # Make the wrapper dir available to login shells too; nushell env.nu already
  # prepends ~/.local/bin for interactive sessions.
  home.sessionPath = [ "$HOME/.local/bin" ];

  # Workspace flakes must be copies, not symlinks: nix snapshots path flakes
  # into the store, so a flake.nix symlink pointing outside the workspace
  # dir dangles. These wrappers are static -- the real shells live in
  # nix/{rust,kotlin}-shell.nix and are pulled in via a path input, so
  # editing those does NOT require re-switching.
  home.activation.workspaceFlakes = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/workspace/rust" "$HOME/workspace/kotlin"
    cp -f "${dotfiles}/nix/workspace-rust.nix" "$HOME/workspace/rust/flake.nix"
    cp -f "${dotfiles}/nix/workspace-kotlin.nix" "$HOME/workspace/kotlin/flake.nix"
  '';
}
