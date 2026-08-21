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

  # Placeholder alacritty theme. DMS (matugen) overwrites
  # ~/.config/alacritty/dank-theme.toml dynamically with the wallpaper
  # palette, so this only fills the gap before the first DMS run.
  dankTheme = pkgs.writeText "dank-theme.toml" ''
    [colors.primary]
    background = "#132738"
    foreground = "#ffffff"

    [colors.cursor]
    text = "#132738"
    cursor = "#ffffff"

    [colors.normal]
    black = "#262626"
    red = "#cc0000"
    green = "#42b63f"
    yellow = "#dd9400"
    blue = "#729fcf"
    magenta = "#bf78cf"
    cyan = "#74cd45"
    white = "#d1b88e"

    [colors.bright]
    black = "#a79e67"
    red = "#ef2929"
    green = "#8ae234"
    yellow = "#ead96b"
    blue = "#729fcf"
    magenta = "#ad7fa8"
    cyan = "#ead96b"
    white = "#eeeeec"
  '';
in
{
  home.username = "doanh";
  home.homeDirectory = "/home/doanh";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    # ---- shell / terminal ----
    nushell
    zellij
    alacritty
    foot
    bat
    ripgrep
    fd
    fzf
    skim
    starship
    zoxide
    carapace
    fastfetch
    opencode
    rumdl

    # ---- editors ----
    helix
    zed-editor
    bash-language-server
    libreoffice-fresh

    # ---- browser ----
    firefox

    # ---- rust toolchain & cargo helpers ----
    cargo
    rustc
    cargo-expand
    cargo-binstall
    cargo-update
    topgrade

    # ---- build tooling ----
    cmake

    # ---- yazi file manager ----
    yazi

    # ---- wayland utilities ----
    wl-clipboard
    wl-clip-persist
    cliphist
    grim
    slurp

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

  programs.antigravity-cli = {
    enable = true;
    defaultModel = "gemini-3.7-flash";
  };

  home.file = {
    # ---- nushell: the repo's my.nu is the real config ----
    ".config/nushell/config.nu".text = "source ${dotfiles}/nushell/my.nu\n";
    ".config/nushell/env.nu".text = "";

    # ---- alacritty (imports dank-theme.toml, see activation below) ----
    ".config/alacritty/alacritty.toml".source = link "${dotfiles}/alacritty/alacritty.toml";

    # ---- helix ----
    ".config/helix/config.toml".source = link "${dotfiles}/helix/config.toml";

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

    # ---- zoxide nushell init (sourced by nushell/env.nu) ----
    ".zoxide.nu".source =
      pkgs.runCommand "zoxide-nushell.nu" { } ''
        ${lib.getExe pkgs.zoxide} init nushell > "$out"
      '';
  };

  # DMS generates dank-theme.toml dynamically; only seed it if missing.
  home.activation.createDankTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.config/alacritty/dank-theme.toml" ]; then
      mkdir -p "$HOME/.config/alacritty"
      cp -f ${dankTheme} "$HOME/.config/alacritty/dank-theme.toml"
    fi
  '';
}
