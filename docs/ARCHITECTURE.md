# Architecture

Serpantinum is split into small, independent pieces. `install.sh` is only an
orchestrator: it sources the modules in order and each module is responsible
for one concern.

## Install flow

```text
install.sh
  ├─ lib/detect.sh          Arch / user / Hyprland detection
  ├─ modules/00-preflight   network + state directories
  ├─ modules/10-packages    missing pacman packages only
  ├─ modules/20-zsh         oh-my-zsh, .zshrc, login shell
  ├─ modules/25-kitty       kitty.conf (natural window size)
  ├─ modules/30-vim         vim-plug, .vimrc, PlugInstall
  ├─ modules/40-hyprland    Lua modules + helpers + live reload
  └─ modules/50-wallpaper   asset install + live swaybg
```

Every module is idempotent and can be re-run alone:

```bash
source lib/common.sh
source lib/detect.sh
source modules/30-vim.sh
```

## Configuration model

Configuration files are **symlinked** from the repository into the home
directory. The repository is the single source of truth:

| Repository | Target |
|---|---|
| `config/zsh/.zshrc` | `~/.zshrc` |
| `config/vim/.vimrc` | `~/.vimrc` |
| `config/kitty/kitty.conf` | `~/.config/kitty/kitty.conf` |
| `config/hypr/*.lua` | `~/.config/hypr/*.lua` |
| `config/serpantinum/env.sh` | `~/.config/serpantinum/env.sh` |
| `bin/*` | `~/.local/bin/*` |
| `assets/wallpapers/serpantinum.jpg` | `~/.local/share/serpantinum/wallpapers/` |

Before replacing anything, `lib/common.sh:backup_file()` copies the previous
file to `~/.local/state/serpantinum/backups/<timestamp>/`.

## Hyprland configuration

Hyprland ≥ 0.57 uses Lua. `hyprland.lua` requires three modules:

* `serpantinum-appearance.lua` — monitors, decorations, input, autostart
  (`swaybg`, `xdg-user-dirs`, VirtualBox clipboard).
* `serpantinum-rules.lua` — **floats every window** and centres it. This is
  what removes automatic tiling: there is no Tiling Shell and no tiling
  layout in use.
* `serpantinum-keybinds.lua` — Ubuntu-style shortcuts. Snapping and monitor
  moves call `bin/serpantinum-snap`, which uses `hyprctl` JSON output and the
  Lua dispatchers (`hl.dsp.window.move/resize`).

## State and data

```text
~/.local/state/serpantinum/
├── installed          # marker (ISO timestamp)
├── source             # path of the clone that installed it
├── hyprland.log       # tty1 autostart log
└── backups/           # timestamped backups of replaced files

~/.local/share/serpantinum/
└── wallpapers/serpantinum.jpg
```

## Extending

* **New package**: add it to `dependencies/arch.txt`.
* **New config file**: add it under `config/` and link it from the relevant
  module with `link_config`.
* **New module**: drop `modules/60-whatever.sh`; it is sourced automatically
  (modules are executed in lexical order).
