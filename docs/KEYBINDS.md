# Keyboard shortcuts

All shortcuts are defined in `config/hypr/serpantinum-keybinds.lua` and follow
Ubuntu's window-management conventions on a **floating** Hyprland desktop
(no Tiling Shell, no automatic tiling).

## Launchers

| Shortcut | Action |
|---|---|
| `Ctrl+Alt+T` | Terminal (`serpantinum-terminal`) |
| `Super+Return` | Terminal (convenience) |
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
| `Super+Up` | Maximize |
| `Super+Down` | Restore if maximized, otherwise minimize |
| `Super+H` | Minimize (hidden `special:minimized` workspace) |
| `Super+Shift+H` | Restore all minimized windows |
| `Super+V` | Toggle floating |
| `Super+F` | Toggle fullscreen |
| `Super+Shift+Left` | Move window to the monitor on the left |
| `Super+Shift+Right` | Move window to the monitor on the right |
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

* `Super+Down` mirrors Ubuntu: restore when the window is maximized, minimize
  otherwise.
* Hyprland has no native minimize; Serpantinum uses a hidden special
  workspace (official Hyprland pattern) and restores windows with
  `Super+Shift+H`.
* Alt+Tab cycles windows directly — Wayland does not expose Ubuntu's
  thumbnail switcher to the compositor.
