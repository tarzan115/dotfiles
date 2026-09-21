{
  config,
  lib,
  pkgs,
  ...
}:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
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
    skim
    starship
    zoxide
    atuin
    carapace
    fastfetch
    rumdl
    gitui
    gh
    pik
    pi-coding-agent
    rtk
    lstr

    # ---- nix / shell linting ----
    shellcheck
    shfmt
    statix
    deadnix
    nixd

    # ---- editors ----
    helix
    gram
    bash-language-server
    libreoffice-stable

    # ---- browser ----
    firefox

    # ---- rust toolchain & cargo helpers ----
    (pkgs.fenix.stable.withComponents [
      "cargo"
      "clippy"
      "rust-src"
      "rustc"
      "rustfmt"
    ])
    pkgs.fenix.stable.rust-analyzer
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
    # Bun runtime + its bundled package manager; replaces node as the
    # default JS/TS toolkit.
    bun
    # Keep a real `node`/npm on PATH for tools that invoke `node` by name.
    nodejs_latest

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
    localsend
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

  # Fcitx is manual-only. The NixOS package registers both XDG autostart
  # and D-Bus activation; commenting out mango's startup command is not enough.
  xdg.configFile."autostart/org.fcitx.Fcitx5.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Fcitx 5
    Hidden=true
  '';
  # User service definitions take precedence over the system registration.
  # Fail activation requests, but allow an explicitly launched `fcitx5 -d`
  # to own the bus name and serve input-method clients normally.
  xdg.dataFile."dbus-1/services/org.fcitx.Fcitx5.service".text = ''
    [D-BUS Service]
    Name=org.fcitx.Fcitx5
    Exec=${pkgs.coreutils}/bin/false
  '';

  home.file = {
    # ---- nushell: the repo's my.nu is the real config ----
    ".config/nushell/config.nu".text = "source ${dotfiles}/nushell/my.nu\n";
    ".config/nushell/env.nu".text = "";

    # ---- kitty ----
    ".config/kitty/kitty.conf".source = link "${dotfiles}/kitty/kitty.conf";

    # ---- helix ----
    ".config/helix/config.toml".source = link "${dotfiles}/helix/config.toml";
    ".config/helix/languages.toml".source = link "${dotfiles}/helix/languages.toml";
    ".config/helix/themes".source = link "${dotfiles}/helix/themes";

    # ---- foot (mango-config submodule) ----
    ".config/foot/foot.ini".source = link "${dotfiles}/mango-config/foot/foot.ini";

    # ---- mango (whole mango-config submodule: compositor + dms fragments) ----
    ".config/mango".source = link "${dotfiles}/mango-config";

    # ---- DankMaterialShell (shell settings, plugins, generated files) ----
    ".config/DankMaterialShell".source = link "${dotfiles}/DankMaterialShell";

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
    ".pi/agent/AGENTS.md".source = link "${dotfiles}/AGENTS.md";
    ".claude/CLAUDE.md".source = link "${dotfiles}/AGENTS.md";
    ".codex/AGENTS.md".source = link "${dotfiles}/AGENTS.md";

    # ---- pi global agent config (settings, extension config, custom agents,
    #      extensions). Runtime state -- sessions/, npm/, git/, tmp/, auth.json,
    #      the memory sqlite files -- stays unmanaged under ~/.pi/agent ----
    ".pi/agent/settings.json".source = link "${dotfiles}/pi/settings.json";
    ".pi/agent/pi-beautiful-tui.json".source = link "${dotfiles}/pi/pi-beautiful-tui.json";
    ".pi/agent/agents".source = link "${dotfiles}/pi/agents";
    ".pi/agent/extensions".source = link "${dotfiles}/pi/extensions";

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
  # editing those does NOT require re-switching. The @DOTFILES@ placeholder
  # is substituted at activation time so the templates stay path-agnostic.
  home.activation.rtkInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${lib.getExe pkgs.rtk} init --agent pi -g --auto-patch 2>/dev/null || true
  '';

  home.activation.workspaceFlakes = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/workspace/rust" "$HOME/workspace/kotlin"
    sed "s|@DOTFILES@|${dotfiles}|g" \
      "${dotfiles}/nix/workspace-rust.nix" > "$HOME/workspace/rust/flake.nix"
    sed "s|@DOTFILES@|${dotfiles}|g" \
      "${dotfiles}/nix/workspace-kotlin.nix" > "$HOME/workspace/kotlin/flake.nix"
  '';
}
