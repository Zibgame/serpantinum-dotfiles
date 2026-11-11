# Serpantinum Dotfiles

Personal Arch Linux environment: **Hyprland** (floating, Ubuntu-like window
management — no Tiling Shell), **Zsh**, **Vim** and a modular installer that
reproduces everything on a fresh VM.

```text
  ____                       _   _
 / ___|  ___ _ __ _ __   __ _| |_(_)_ __  _   _ _ __ ___
 \___ \ / _ \ '__| '_ \ / _` | __| | '_ \| | | | '_ ` _ \
  ___) |  __/ |  | |_) | (_| | |_| | | | | |_| | | | | |
 |____/ \___|_|  | .__/ \__,_|\__|_|_| |_|\__,_|_| |_| |_|
                 |_|
```

## Quick start

```bash
git clone git@github.com:Zibgame/serpantinum-dotfiles.git
cd serpantinum-dotfiles
./install.sh
```

Then log out and back in (or run `exec zsh`) to load Zsh. If Hyprland is
running, the new configuration is reloaded automatically.

Check the result:

```bash
serpantinum status
serpantinum doctor
```

## What it installs

| Part | Details |
|---|---|
| Packages | Only the missing ones, from `dependencies/arch.txt` (pacman) |
| Zsh | oh-my-zsh + your `.zshrc`, login shell switched to Zsh |
| Vim | vim-plug + your `.vimrc` + all plugins (`PlugInstall`) |
| Hyprland | Modular Lua config: appearance, rules, Ubuntu-like keybinds |
| Helpers | `serpantinum-terminal`, `serpantinum-snap`, `serpantinum` CLI |

## Architecture

```text
serpantinum-dotfiles/
├── install.sh                     # entry point (idempotent)
├── lib/
│   ├── common.sh                  # logging, backups, symlinks
│   ├── detect.sh                  # distro / environment detection
│   └── status.sh                  # status output
├── modules/                       # one module per concern
│   ├── 00-preflight.sh
│   ├── 10-packages.sh
│   ├── 20-zsh.sh
│   ├── 25-kitty.sh
│   ├── 30-vim.sh
│   ├── 40-hyprland.sh
│   ├── 45-autostart.sh
│   └── 48-wallpaper-picker.sh
├── dependencies/
│   ├── arch.txt                    # Arch-family packages (pacman)
│   ├── debian.txt                  # Debian/Ubuntu/Kali (apt)
│   ├── fedora.txt                  # Fedora/RHEL (dnf)
│   ├── suse.txt                    # openSUSE (zypper)
│   └── void.txt                    # Void Linux (xbps)
├── config/
│   ├── zsh/.zshrc
│   ├── vim/.vimrc
│   ├── kitty/kitty.conf
│   ├── foot/foot.ini
│   ├── hypr/
│   │   ├── hyprland.lua           # entry point (require)
│   │   ├── serpantinum-appearance.lua
│   │   ├── serpantinum-rules.lua
│   │   └── serpantinum-keybinds.lua
│   ├── systemd/user/              # autostart watcher unit
│   └── serpantinum/env.sh         # environment + tty1 autostart
├── bin/
│   ├── serpantinum                # management CLI
│   ├── serpantinum-snap           # Ubuntu-like window snapping
│   ├── serpantinum-terminal       # terminal launcher (software GL in VMs)
│   └── serpantinum-autostart.sh   # robust shell launcher
└── docs/
    ├── ARCHITECTURE.md
    └── KEYBINDS.md
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the design and
[docs/KEYBINDS.md](docs/KEYBINDS.md) for the full shortcut list.

## Ubuntu-like shortcuts (no tiling)

Serpantinum floats every window and implements Ubuntu's window management
explicitly:

| Shortcut | Action |
|---|---|
| `Ctrl+Alt+T` | Terminal |
| `Alt+Tab` / `Alt+Shift+Tab` | Next / previous window |
| `Alt+F4` | Close window |
| `Super+Left` / `Super+Right` | Snap to left / right half |
| `Super+Up` | Maximize |
| `Super+Down` | Restore, or minimize |
| `Super+H` | Minimize |
| `Super+Shift+H` | Restore minimized windows |
| `Super+Shift+Left/Right` | Move window to monitor left/right |
| `Ctrl+Alt+Left/Right` | Previous / next workspace |
| `Ctrl+Alt+Shift+Left/Right` | Move window to previous/next workspace |
| `Super+1..9` / `Super+0` | Switch to workspace |
| `Super+Shift+1..9` / `Super+0` | Move window to workspace |
| `Super+Shift+Up/Down` | Move window to workspace above/below |
| `Super+V` | Toggle floating |
| `Super+F` | Toggle fullscreen |
| `Print` | Screenshot to `~/Pictures/Screenshots` |
| `Super+Shift+S` | Region screenshot to clipboard |
| `Super+D` / `Super+A` | Application launcher (wofi) |
| `Super+Return` | Terminal (convenience) |

## Idempotence and safety

* Running `./install.sh` again only installs missing packages and refreshes
  configuration links.
* Every existing file that would be replaced is copied to
  `~/.local/state/serpantinum/backups/<timestamp>/` first.
* No private key is ever stored in this repository or on the target machine.

## Options

```text
./install.sh --help
./install.sh --status
./install.sh --no-packages
./install.sh --no-shell
./install.sh --no-vim
```

## Limitations

* Hyprland has no native "minimize" concept; Serpantinum implements it with a
  hidden special workspace (`special:minimized`), like the official Hyprland
  snippet. Windows are restored with `Super+Shift+H`.
* The Alt+Tab switcher cycles windows directly (no thumbnail overlay):
  Wayland compositors do not expose Ubuntu's switcher UI.
* Snapping is pixel-based (`serpantinum-snap`) because windows are floating by
  design — there is no automatic tiling anywhere.
* The console-first autostart (`tty1` → Hyprland) is guarded: it only runs on
  `tty1` without an existing Wayland session.
