# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, inputs, pkgs, lib, ... }:

let
  # Session script started by greetd after login. PATH ordering matters:
  # /run/wrappers/bin must come first so setuid tools (sudo, su, passwd, ...)
  # resolve to their wrappers instead of the raw store binaries in
  # /run/current-system/sw/bin.
  mango-session = pkgs.writeShellScript "mango-session" ''
    export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/usr/bin:/bin:$PATH"
    export DBUS_SESSION_BUS_ADDRESS="''${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"
    exec ${config.programs.mango.package}/bin/mango
  '';
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "doanh-nixos"; # Define your hostname.
  networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Ho_Chi_Minh";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "vi_VN";
    LC_IDENTIFICATION = "vi_VN";
    LC_MEASUREMENT = "vi_VN";
    LC_MONETARY = "vi_VN";
    LC_NAME = "vi_VN";
    LC_NUMERIC = "vi_VN";
    LC_PAPER = "vi_VN";
    LC_TELEPHONE = "vi_VN";
    LC_TIME = "vi_VN";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "colemak";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # nushell is the login shell (all user-level packages live in home-manager).
  users.users."doanh" = {
    isNormalUser = true;
    description = "doanh";
    shell = pkgs.nushell;
    packages = with pkgs; [];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # User-level packages (zed, rust, yazi, ...) are managed by
  # home-manager in ./home.nix.
  environment.systemPackages = with pkgs; [
     git
     gnupg           # GPG for adguardvpn-cli install
     qt6.qtwayland   # QT support for Wayland interfaces
     pamixer         # Audio control via DMS widgets
     brightnessctl   # Brightness sliders
     xdg-desktop-portal     # Required for screen sharing via portal protocol
     xdg-desktop-portal-wlr # Wayland (wlroots-based) portal backend for MangoWM
  ];

  # PipeWire — replaces PulseAudio and provides the WebRTC screen-capture
  # pipeline that Firefox uses for Google Meet screen sharing on Wayland.
  services.pipewire = {
    enable = true;
    alsa.enable = true;       # ALSA compat shim
    alsa.support32Bit = true; # 32-bit app support (e.g. Steam)
    pulse.enable = true;      # PulseAudio compat shim (pamixer, bluez-alsa)
    wireplumber.enable = true; # Session/policy manager
  };
  # PulseAudio must be off when PipeWire is the audio server
  services.pulseaudio.enable = false;
  security.rtkit.enable = true; # Gives PipeWire real-time priority

  # dconf service (D-Bus activated) — GTK/GNOME apps (kooha, DMS dialogs)
  # persist their GSettings through it. Without it they log
  # "ServiceUnknown: The name is not activatable" and lose settings.
  programs.dconf.enable = true;

  # Vietnamese input: fcitx5 + Unikey engine. The module exports
  # GTK_IM_MODULE/QT_IM_MODULE/XMODIFIERS globally and installs
  # fcitx5-with-addons into systemPackages; the daemon is launched by
  # mango-config/autostart.sh (`fcitx5 --replace -d`). fcitx5-gtk ships the
  # GTK IM module that GTK_IM_MODULE=fcitx loads — without it GTK apps log
  # "No IM module matching GTK_IM_MODULE=fcitx found" and typing breaks.
  # settings.inputMethod seeds /etc/xdg/fcitx5/profile as the default;
  # per-user tweaks in ~/.config/fcitx5/profile take priority over it.
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-gtk
      qt6Packages.fcitx5-unikey
    ];
    fcitx5.settings.inputMethod = {
      "Groups/0" = {
        Name = "Default";
        DefaultLayout = "us";
        DefaultIM = "unikey";
      };
      "Groups/0/Items/0" = {
        Name = "keyboard-us";
        Layout = "";
      };
      "Groups/0/Items/1" = {
        Name = "unikey";
        Layout = "";
      };
      "GroupOrder"."0" = "Default";
    };
  };

  # Move the hand-made ~/.config/xdg-desktop-portal/portals.conf aside so
  # mango's module-generated /etc/xdg/xdg-desktop-portal/mango-portals.conf
  # rules instead: it routes ScreenCast/Screenshot to wlr, disables Inhibit
  # (stops "Inhibiting other than idle not supported" journal spam), and
  # maps Secret to gnome-keyring if that ever gets installed.

  # Pin xdg-desktop-portal-wlr to 0.7.x from nixos-25.05: the 0.8.x rewrite
  # picks its ext-image-copy-capture path on mango and fails with
  # "started frame without buffer" (emersion/xdg-desktop-portal-wlr#369).
  # 0.7.x uses wlr-screencopy, which mango (wlroots) supports.
  nixpkgs.overlays = [
    (final: prev: {
      xdg-desktop-portal-wlr =
        inputs.nixpkgs-old.legacyPackages.${prev.stdenv.hostPlatform.system}.xdg-desktop-portal-wlr;
    })
  ];

  # Skip the wlr portal's picker entirely: "none" makes xdwim 0.7.x
  # auto-select the output named below, falling back to the first monitor.
  # ("none" is only understood by 0.7.x; 0.8.x removed it.)
  xdg.portal.wlr.settings = {
    screencast = {
      chooser_type = "none";
      # output_name = "eDP-1";
    };
  };

  # Fonts (JetBrains Mono Nerd Font used by kitty/foot)
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # Keyboard remapping (Colemak + caps-lock navigation) via kanata,
  # from the kanata config folder: kanata/config.kbd
  services.kanata = {
    enable = true;
    keyboards.doanh = {
      configFile = "${inputs.kanata}/config.kbd";
    };
  };

  # Enable MangoWM compositor
  programs.mango.enable = true;

  # graphical-session.target ships with RefuseManualStart=yes, which makes
  # mango's `systemctl --user start graphical-session.target` (mango-config/
  # config.conf) fail with "Operation refused". As a result dms.service
  # (WantedBy=graphical-session.target) never starts. Lift the restriction so
  # the compositor can bring up the target itself. (systemd.user.units defaults
  # to overrideStrategy="asDropinIfExists", so this becomes a drop-in on top of
  # the systemd-shipped target.)
  systemd.user.units."graphical-session.target" = {
    text = ''
      [Unit]
      RefuseManualStart=no
    '';
  };

  # tuigreet configuration file — sourced from the dotfiles repo and deployed
  # to /etc/tuigreet/config.toml so the greeter user can read it.
  # Edit dotfiles/tuigreet/config.toml, then rebuild to apply changes.
  environment.etc."tuigreet/config.toml".source =
    "${inputs.tuigreet-config}/config.toml";

  # Password login into mango at boot. greetd shows tuigreet, which asks for
  # the password before handing off to the session script. The session script
  # sets the session bus + PATH, then hands off to mango; mango's config.conf
  # (symlinked from the dotfiles) then starts graphical-session.target, which
  # pulls in the dms.service shell.
  services.greetd = {
    enable = true;
    useTextGreeter = true;
    settings = {
      default_session = {
        user = "greeter";
        command = "${pkgs.tuigreet}/bin/tuigreet --config /etc/tuigreet/config.toml --time --cmd ${mango-session}";
      };
    };
  };

  # Enable DankMaterialShell and all available modules
  programs.dms-shell = {
    enable = true;

    # Service & Auto-start configuration
    systemd = {
      enable = true;            # Enable systemd service for auto-start[span_1](start_span)[span_1](end_span)
      restartIfChanged = true;  # Auto-restart service on rebuilds[span_2](start_span)[span_2](end_span)
    };

    # Integrated Feature Toggles
    enableSystemMonitoring = true; # Enables dgop system monitoring[span_3](start_span)[span_3](end_span)
    enableVPN = true;              # Enables VPN management widget[span_4](start_span)[span_4](end_span)
    enableDynamicTheming = true;   # Wallpaper-based theming via matugen[span_5](start_span)[span_5](end_span)
    enableAudioWavelength = true;  # Audio visualizer via cava[span_6](start_span)[span_6](end_span)
    enableCalendarEvents = true;   # Calendar integration via khal[span_7](start_span)[span_7](end_span)

    # Declarative Community Plugins
    plugins = {
    };
  };

  # Required PAM configuration for U2F/FIDO2 lock screen unlock
  security.pam.services."dankshell-u2f".text = ''
    auth     required ${pkgs.pam_u2f}/lib/security/pam_u2f.so cue
    account  required pam_permit.so
  '';

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "antigravity-cli"
  ];

  # Enable nix-command and flakes so `nix run`, `nix shell`, etc. work
  # without passing --extra-experimental-features every time.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Bluetooth — bluez stack + blueman applet for GUI pairing.
  # hsphfpd handles headset/handsfree profiles; bluez-alsa/pipewire bridges
  # A2DP so audio devices show up automatically in PipeWire/PulseAudio.
  hardware.bluetooth = {
    enable = true;           # Enable the bluez kernel stack
    powerOnBoot = true;      # Power the adapter on at boot
    settings = {
      Policy.AutoEnable = true;   # Auto-enable adapter after suspend/resume
      General = {
        Experimental = true;      # Enable battery reporting and other extras
        FastConnectable = true;   # Reduce reconnect latency
      };
    };
  };

  services.blueman.enable = true; # System tray / GUI pairing tool

  # Ensure doanh can manage bluetooth devices without sudo
  users.users."doanh".extraGroups = [ "networkmanager" "wheel" "bluetooth" ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?

}
