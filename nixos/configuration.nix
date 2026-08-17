# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, inputs, pkgs, ... }:

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
    extraGroups = [ "networkmanager" "wheel" ];
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
  ];

  # Fonts (JetBrains Mono Nerd Font used by alacritty/foot)
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # Keyboard remapping (Colemak + caps-lock navigation) via kanata,
  # from the caps submodule: caps/kanata/config.kbd
  services.kanata = {
    enable = true;
    keyboards.doanh = {
      configFile = "${inputs.caps}/kanata/config.kbd";
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
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd ${mango-session}";
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

 
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

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
