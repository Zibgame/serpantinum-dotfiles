# Keyboard shortcuts

Terminal shortcuts are defined in `config/hypr/hyprland.lua`; other shortcuts are
defined in `config/hypr/serpantinum-keybinds.lua`. They follow
Ubuntu's window-management conventions on a **floating** Hyprland desktop
(no Tiling Shell, no automatic tiling).

## Launchers

| Shortcut | Action |
|---|---|
| `Ctrl+Alt+T` | Terminal (Foot sous VirtualBox, Kitty ailleurs) |
| `Super+Return` | Terminal (idem) |
| `Super+T` | Terminal (raccourci alternatif) |
| `Super+Shift+Return` | Terminal de secours direct (Foot) |
| `Super+D` | Application launcher (wofi) |
| `Super+A` | Application launcher (wofi) |

## Windows

| Shortcut | Action |
|---|---|
| `Alt+Tab` | Next window |
| `Alt+Shift+Tab` | Previous window |
| `Alt+F4` | Close window |
| `Super+Q` | Close window (convenience) |
| `Super+Left` | Snap to the left half |
| `Super+Right` | Snap to the right half |
| `Super+Up` | First press: upper half; second press: full work area below the top bar |
| `Super+Down` | Restore maximized/fullscreen window; otherwise do nothing (never minimize or close) |
| `Super+H` | Minimize (hidden `special:minimized` workspace) |
| `Super+Shift+H` | Restore all minimized windows |
| `Super+V` | Toggle floating |
| `Super+F` | Toggle fullscreen |
| `Super+Shift+Left` | Move window to the monitor on the left |
| `Super+Shift+Right` | Move window to the monitor on the right |

`Super+Left`, `Super+Right` and `Super+Up` use the available monitor work area below the
Serpantinum top bar, while keeping all windows floating. The fallback top bar
height is 32px if Hyprland has not reserved the panel; override it with
`SERPANTINUM_TOP_BAR_HEIGHT` if your bar size differs.
| `Super+LMB drag` | Move window |
| `Super+RMB drag` | Resize window |

## Workspaces

| Shortcut | Action |
|---|---|
| `Super+1..9` | Switch to workspace 1–9 |
| `Super+0` | Switch to workspace 10 |
| `Super+Shift+1..9` | Move window to workspace 1–9 |
| `Super+Shift+0` | Move window to workspace 10 |
| `Ctrl+Alt+Left` | Previous workspace |
| `Ctrl+Alt+Right` | Next workspace |
| `Ctrl+Alt+Shift+Left` | Move window to the previous workspace |
| `Ctrl+Alt+Shift+Right` | Move window to the next workspace |
| `Super+Shift+Up` | Move window to the workspace above |
| `Super+Shift+Down` | Move window to the workspace below |

## Screenshots and media

| Shortcut | Action |
|---|---|
| `Print` | Full screenshot to `~/Pictures/Screenshots/` |
| `Super+Shift+S` | Region screenshot to the clipboard |
| `XF86AudioRaiseVolume` | Volume +5% |
| `XF86AudioLowerVolume` | Volume -5% |
| `XF86AudioMute` | Mute toggle |

## Notes

* `Super+Down` restores maximized/fullscreen windows and leaves already-normal
  floating windows untouched. Use `Super+H` to minimize explicitly.
* Hyprland has no native minimize; Serpantinum uses a hidden special
  workspace (official Hyprland pattern) and restores windows with
  `Super+Shift+H`.
* Alt+Tab cycles windows directly — Wayland does not expose Ubuntu's
  thumbnail switcher to the compositor.
