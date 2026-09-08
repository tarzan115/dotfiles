#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Windows bootstrap for the dotfiles repo: installs tools and wires up configs.
.NOTES
  Mirrors init-macos.sh's partition: non-Rust/GUI tools come from a package
  manager (winget here, brew on macOS), Rust CLI tools come from cargo-binstall.
  NixOS is configured declaratively via home.nix — this script is NOT used for
  NixOS (handled by `nixos-install --flake`). macOS uses init-macos.sh. Windows
  uses THIS script.

  Requirements:
    - Windows 10/11 with winget (App Installer) installed
    - PowerShell 7+ (pwsh). Install it if missing:
        winget install --id Microsoft.PowerShell

  What gets wired up (all portable configs). Linux-only dirs (nixos/, nix/,
  mango-config/, tuigreet/) and the bash bin/ wrappers are intentionally
  skipped on Windows. kitty is NOT supported on native Windows (it needs GL on
  Linux/macOS only) — use Windows Terminal here; kitty still works over WSL.
  topgrade IS installed (it's fully supported on Windows, config auto-generated
  at %APPDATA%\topgrade.toml); only the repo's NixOS-specific topgrade.toml is
  skipped. zellij default shell / starship / helix all run natively.
#>
[CmdletBinding()]
param(
    [switch]$Trace
)

$ErrorActionPreference = 'Stop'
if ($Trace) { Set-PSDebug -Trace 1 }

function Info { Write-Host "[setup-windows] $args" -ForegroundColor Cyan }
function Warn { Write-Host "[setup-windows] WARN: $args" -ForegroundColor Yellow }

# ---- Windows-only guard (pwsh only: $IsWindows exists in PS Core) ----
if ($null -eq (Get-Variable IsWindows -ErrorAction SilentlyContinue)) {
    throw "setup-windows.ps1 requires PowerShell 7+ (pwsh). Install it: winget install Microsoft.PowerShell"
}
if (-not $IsWindows) {
    throw "setup-windows.ps1 must run on Windows. Current OS: $([System.Environment]::OSVersion)"
}

# Script lives at the repo root (the single source of truth).
$DOTFILES = $PSScriptRoot
$CONFIG_DIR = Join-Path $HOME '.config'
$APPDATA = [Environment]::GetFolderPath('ApplicationData')

# Re-read the machine+user Path so freshly installed tools (especially rustup &
# winget user-scope installs) are reachable from this session.
function Refresh-Path {
    $env:PATH = "$([Environment]::GetEnvironmentVariable('Path','Machine'));$([Environment]::GetEnvironmentVariable('Path','User'))"
}

# ---- winget: non-Rust / GUI tools (brew roles on macOS) ----
# Each maps { winget-id ; command to verify after install }.
$wingetPkgs = @(
    @{ Id = 'Microsoft.PowerShell';          Cmd = 'pwsh' }
    @{ Id = 'Microsoft.WindowsTerminal';     Cmd = 'wt' }
    @{ Id = 'Git.Git';                       Cmd = 'git' }
    @{ Id = 'Rustlang.Rustup';               Cmd = 'rustup' }
    @{ Id = 'Helix.Helix';                   Cmd = 'hx' }
    @{ Id = 'carapace-sh.carapace-bin';      Cmd = 'carapace' }  # Go, not cargo-able
)
Refresh-Path
foreach ($p in $wingetPkgs) {
    if (Get-Command $p.Cmd -ErrorAction SilentlyContinue) {
        Info "already installed: $($p.Cmd)"
        continue
    }
    try {
        winget install --id $p.Id -e --source winget --silent `
            --accept-package-agreements --accept-source-agreements 2>$null | Out-Null
        Refresh-Path
        if (Get-Command $p.Cmd -ErrorAction SilentlyContinue) {
            Info "installed $($p.Cmd) via winget"
        } else {
            Warn "installed '$($p.Id)' but '$($p.Cmd)' is not on PATH — open a new terminal"
        }
    }
    catch {
        Warn "winget install '$($p.Id)' failed: $_ — install '$($p.Cmd)' manually"
    }
}

# ---- rust toolchain (rustup; matching macOS rustup install) ----
if (Get-Command rustup -ErrorAction SilentlyContinue) {
    rustup update stable
    Refresh-Path
}

# ---- Rust CLI tools via cargo-binstall (prebuilt binaries when available;
#      auto-falls back to `cargo install`). Mirrors the macOS cargo-binstall list.
#      topgrade is fully supported on Windows (upgrades winget + PowerShell
#      modules); it auto-generates %APPDATA%\topgrade.toml on first run — the
#      repo's topgrade.toml is NixOS-only and intentionally skipped. ----
if (Get-Command cargo -ErrorAction SilentlyContinue) {
    if (-not (Get-Command cargo-binstall -ErrorAction SilentlyContinue)) {
        cargo install cargo-binstall --locked
    }
    $cargoPkgs = @(
        'nu starship zellij yazi-fm bat eza ripgrep fd-find zoxide atuin
         topgrade git-delta skim sccache kanata'
    )
    cargo binstall -y $($cargoPkgs -split '\s+')

    foreach ($cmd in @('nu','starship','zellij','yazi','bat','eza','rg','fd','zoxide','atuin','topgrade','delta','sk','sccache','kanata')) {
        if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
            Warn "expected '$cmd' missing after cargo-binstall — check the binstall output above"
        }
    }
}

# ---- dotfiles: copy configs so the repo stays the source of truth.
#      Windows is copied (not symlinked) — symlinks need admin/Developer Mode. ----
New-Item -ItemType Directory -Force -Path $CONFIG_DIR | Out-Null

# helix
New-Item -ItemType Directory -Force -Path (Join-Path $APPDATA 'helix') | Out-Null
Copy-Item -Force (Join-Path $DOTFILES 'helix\config.toml') (Join-Path $APPDATA 'helix\config.toml')
Copy-Item -Recurse -Force (Join-Path $DOTFILES 'helix\themes') (Join-Path $APPDATA 'helix\themes')

# starship
Copy-Item -Force (Join-Path $DOTFILES 'starship\starship.toml') (Join-Path $CONFIG_DIR 'starship.toml')

# zellij
New-Item -ItemType Directory -Force -Path (Join-Path $APPDATA 'zellij') | Out-Null
Copy-Item -Force (Join-Path $DOTFILES 'zellij\config.kdl') (Join-Path $APPDATA 'zellij\config.kdl')

# kitty is NOT supported on native Windows (Linux/macOS only; maintainer-confirmed).
# If you run it through WSL2, set it up INSIDE WSL instead:
#   ln -s ~/dotfiles/kitty/kitty.conf ~/.config/kitty/kitty.conf
# Windows setup here uses Windows Terminal for the native nushell session.

# yazi (fully portable; plugins/flavors are gitignored -> restore via `ya pack -i`)
New-Item -ItemType Directory -Force -Path (Join-Path $APPDATA 'yazi') | Out-Null
Copy-Item -Recurse -Force (Join-Path $DOTFILES 'yazi\*') (Join-Path $APPDATA 'yazi')
if (Get-Command ya -ErrorAction SilentlyContinue) {
    Push-Location (Join-Path $APPDATA 'yazi')
    ya pack -i
    Pop-Location
}

# cargo (rustc-wrapper = sccache; works on Windows)
New-Item -ItemType Directory -Force -Path (Join-Path $HOME '.cargo') | Out-Null
Copy-Item -Force (Join-Path $DOTFILES 'cargo\config.toml') (Join-Path $HOME '.cargo\config.toml')

# ---- nushell: repo's my.nu stays the single source of truth ----
$nu = (Get-Command nu -ErrorAction SilentlyContinue).Source
if ($nu) {
    # Let nu resolve its own config/cache dirs instead of guessing APPDATA layout.
    $nuConfigDir = (& $nu --no-config-file -c 'print $nu.config-dir' | Select-Object -First 1)
    $nuCacheDir  = (& $nu --no-config-file -c 'print $nu.cache-dir'  | Select-Object -First 1)
    New-Item -ItemType Directory -Force -Path $nuConfigDir, $nuCacheDir | Out-Null

    $sourcePath = (Join-Path $DOTFILES 'nushell\my.nu') -replace '\\', '/'
    "source '$sourcePath'" | Set-Content -Encoding utf8 (Join-Path $nuConfigDir 'config.nu')
    '' | Set-Content -Encoding utf8 (Join-Path $nuConfigDir 'env.nu')

    # generated init files (guarded by config.nu/env.nu, so a missing one won't break startup)
    New-Item -ItemType Directory -Force -Path (Join-Path $HOME '.config') | Out-Null
    starship init nu    | Set-Content -Encoding utf8 (Join-Path $HOME '.config\starship.nu')
    carapace _carapace nushell | Set-Content -Encoding utf8 (Join-Path $nuCacheDir 'carapace.nu')
    zoxide init nushell | Set-Content -Encoding utf8 (Join-Path $HOME '.zoxide.nu')
    atuin init nu       | Set-Content -Encoding utf8 (Join-Path $HOME '.atuin.nu')

    # nu on Windows reads %PATH%; rustup's bin dir lives in ~/.cargo — ensure it's visible.
    $cargoBin = Join-Path $HOME '.cargo\bin'
    if (Test-Path $cargoBin -and $env:PATH -notlike "*$cargoBin*") {
        $env:PATH = "$cargoBin;$env:PATH"
        [Environment]::SetEnvironmentVariable('Path', $env:PATH, 'User')
    }
}

# ---- global AI-tool rules: repo AGENTS.md is the single source of truth ----
New-Item -ItemType Directory -Force -Path (Join-Path $CONFIG_DIR 'opencode'), (Join-Path $HOME '.claude'), (Join-Path $HOME '.codex') | Out-Null
Copy-Item -Force (Join-Path $DOTFILES 'AGENTS.md') (Join-Path $CONFIG_DIR 'opencode\AGENTS.md')
Copy-Item -Force (Join-Path $DOTFILES 'AGENTS.md') (Join-Path $HOME '.claude\CLAUDE.md')
Copy-Item -Force (Join-Path $DOTFILES 'AGENTS.md') (Join-Path $HOME '.codex\AGENTS.md')

# ---- kanata: Windows copy of config.kbd.
#      The linux-dev-names-include block is Linux-only -> stripped. kanata
#      ignores unapplicable device blocks on other platforms (like macOS), but
#      the Windows copy stays clean. `windows-altgr` mitigates ralt/AltGr
#      misbehaviour on the LLHOOK (kanata.exe) backend. ----
$kanata = (Get-Command kanata -ErrorAction SilentlyContinue).Source
if ($kanata) {
    New-Item -ItemType Directory -Force -Path (Join-Path $APPDATA 'kanata') | Out-Null
    $kbd = Get-Content -Raw (Join-Path $DOTFILES 'kanata\config.kbd')
    $kbd = [regex]::Replace($kbd, '(?s)linux-dev-names-include\s*\(.*?\)\s*', '')
    $kbd = $kbd -replace '\(defcfg\s*', "`(defcfg`r`n  windows-altgr add-lctl-release    ;; Windows: ralt/AltGr mitigation (kanata ALTGR docs)`r`n  "
    Set-Content -Encoding utf8 -Path (Join-Path $APPDATA 'kanata\config.kbd') -Value $kbd

    # Autostart on login without a console window (HKCU Run key via the
    # registry provider — avoids reg.exe quoting pitfalls).
    # Default winget/cargo-provided kanata.exe uses the winIOv2/LLHOOK backend,
    # which needs no driver. For the lower-level Interception driver, install it
    # and use kanata_wintercept.exe instead.
    $cfg = Join-Path $APPDATA 'kanata\config.kbd'
    $cmd = "$env:SystemRoot\System32\conhost.exe --headless `"$kanata`" --cfg `"$cfg`""
    $runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    New-Item -Path $runKey -Force | Out-Null
    Set-ItemProperty -Path $runKey -Name 'Kanata' -Value $cmd
    Info "kanata wired up (autostarts on login via HKCU\...\Run); config: $cfg"
    Warn "kanata best-effort: if keys don't register, install the Interception driver and use kanata_wintercept.exe"
}

# ---- git ----
if (Get-Command git -ErrorAction SilentlyContinue) {
    git config --global user.email "doanhlv@duck.com"
    git config --global user.name "Doanh Van Luong"
    git config --global core.pager delta
    git config --global interactive.diffFilter 'delta --color-only'
    git config --global delta.navigate true
    git config --global merge.conflictStyle zdiff3
    git config --global delta.line-numbers true
    git config --global delta.side-by-side true
}

Info "Done. Open a fresh pwsh/nu window (or log out/in) so PATH and kanata pick up."
Info "Verify: nu --version; hx --version; starship --version; kanata (should remap CapsLock)."