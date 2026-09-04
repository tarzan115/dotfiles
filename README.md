# dotfiles

NixOS configuration with flake-based module system, Home Manager, MangoWM, and DankMaterialShell.

## Fresh Install Guide

### Prerequisites

- Bootable NixOS USB (download from [nixos.org](https://nixos.org/download/))
- Internet connection
- Git

### 1. Boot into NixOS live environment

Boot from the USB and select "Graphical Installer" or "Install (CLI)".

### 2. Partition disks

Example for a single disk with UEFI:

```bash
# Create partitions (adjust /dev/sdX for your disk)
gdisk /dev/sdX

# Partition layout:
#   1: EFI System Partition (512M, type EF00)
#   2: Linux filesystem (remaining space, type 8300)
```

Format and mount:

```bash
mkfs.fat -F32 /dev/sdX1 -n BOOT
mkfs.ext4 /dev/sdX2 -n nixos

mount /dev/sdX2 /mnt
mkdir -p /mnt/boot
mount /dev/sdX1 /mnt/boot
```

### 3. Generate hardware configuration

```bash
nixos-generate-config --root /mnt
```

This creates `/mnt/etc/nixos/hardware-configuration.nix`.

### 4. Clone dotfiles

```bash
nix-env -iA nixos.git
git clone --recurse-submodules https://github.com/tarzan115/dotfiles.git /mnt/home/doanh/dotfiles
```

If you already cloned without `--recurse-submodules`:

```bash
cd /mnt/home/doanh/dotfiles
git submodule update --init --recursive
```

### 5. Customize for your machine

Edit these files for your new machine:

**`nixos/flake.nix`** - Update the hostname and user:

- Line 25: Change `kanata` path to your username: `path:/home/YOUR_USER/dotfiles/kanata`
- Line 31: Change `nixosConfigurations.doanh-nixos` to your desired hostname
- Line 41: Change `home-manager.users.doanh` to your username

**`nixos/configuration.nix`** - Update system settings:

- Line 28: Change `networking.hostName` to match your flake hostname
- Line 39: Change `time.timeZone` to your timezone
- Line 44-54: Change locale settings if needed
- Line 64-70: Change `users.users."doanh"` to your username

**`nixos/home.nix`** - Update user settings:

- Line 9: Change `dotfiles` path to your username: `/home/YOUR_USER/dotfiles`
- Line 48: Change `home.username` to your username
- Line 49: Change `home.homeDirectory` to your home directory
- Line 105-106: Update git user name and email

### 6. Copy hardware configuration

```bash
cp /mnt/etc/nixos/hardware-configuration.nix /mnt/home/doanh/dotfiles/nixos/
```

### 7. Install NixOS

```bash
cd /mnt/home/doanh/dotfiles/nixos
nixos-install --flake . --no-root-passwd
```

### 8. Post-install

```bash
# Set user password
passwd doanh

# Reboot
reboot
```

### 9. Verify

After reboot, verify everything works:

```bash
nixos-rebuild switch --flake ~/dotfiles/nixos
```

## Updating the System

```bash
# Update all flake inputs (nixpkgs, home-manager, etc.)
nix flake update

# Apply updates
sudo nixos-rebuild switch --flake ~/dotfiles/nixos
```

## Adding Packages

- **System packages**: Edit `nixos/configuration.nix` (line 76-81)
- **User packages**: Edit `nixos/home.nix` (line 52-99)
- **New NixOS module**: Add flake input in `nixos/flake.nix`, register in `modules` list

## macOS Setup

The repo works on macOS too — most configs are cross-platform (`kitty`, `helix`,
`starship`, `yazi`, `zellij`, `cargo`, `topgrade.toml`). The nushell config
switches paths and package-manager helpers on `$nu.os-info.name`, so the same
files are used on both systems.

Run the bootstrap script on your Mac once (installs Homebrew + tools, wires up
configs, and loads kanata as a LaunchAgent):

```bash
./init-macos.sh
```

NixOS installs never run this — a fresh NixOS setup is purely declarative
(`nixos-install --flake ~/dotfiles/nixos`), so `init-macos.sh` is macOS-only.

Notes:

- `nixos/`, `mango-config/`, and `tuigreet/` are NixOS/Linux-only and are not
  used on macOS.
- `topgrade.toml` is NixOS-specific (flake update + rebuild), so it is not
  installed on macOS — topgrade auto-generates its own config there (brew).
- Kanata runs via `kanata/kanata.plist` (LaunchAgent) on macOS; on NixOS it runs
  via `services.kanata`. The NixOS kanata module only reads `config.kbd`, so the
  plist is harmless there.
- `config.kbd`'s `linux-dev-names-include` block is Linux-only and ignored by
  kanata on macOS.

## Directory Structure

```
dotfiles/
├── nixos/
│   ├── flake.nix              # Flake entry point
│   ├── configuration.nix      # System configuration
│   ├── hardware-configuration.nix  # Hardware-specific (per-machine)
│   ├── home.nix               # Home Manager user config
│   └── zellij-config.kdl      # Zellij config
├── kitty/                     # Terminal config
├── helix/                     # Editor config
├── nushell/                   # Shell config
├── starship/                  # Prompt config
├── yazi/                      # File manager config
├── kanata/                    # Kanata keyboard remapping (CapsLock nav)
└── mango-config/              # Git submodule: MangoWM + DMS fragments
```

## Troubleshooting

**Build fails after hardware change:**
Regenerate hardware config:
```bash
sudo nixos-generate-config --show-hardware-config > ~/dotfiles/nixos/hardware-configuration.nix
sudo nixos-rebuild switch --flake ~/dotfiles/nixos
```

**Submodule errors:**
```bash
cd ~/dotfiles
git submodule update --init --recursive
```

**Rollback to previous generation:**
```bash
# Reboot and select previous generation in systemd-boot menu
# Or:
sudo nixos-rebuild switch --flake ~/dotfiles/nixos --rollback
```
