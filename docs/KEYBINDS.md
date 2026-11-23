# Keyboard shortcuts

Terminal shortcuts are defined in `config/hypr/hyprland.lua`; other shortcuts are
defined in `config/hypr/serpantinum-keybinds.lua`. They follow Windows and
Ubuntu window-management conventions on a **floating** Hyprland desktop
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
| `Alt+Tab` | Hypr App Switcher: next window (visual carousel) |
| `Alt+Shift+Tab` | Hypr App Switcher: previous window |
| `Alt+F4` | Close window |
| `Super+Q` | Close window (convenience) |
| `Super+Left` | Snap to the left half |
| `Super+Right` | Snap to the right half |
| `Super+Up` | Focus and maximize the window under/nearest the cursor |
| `Super+Down` | Restore maximize/fullscreen, restore pre-snap geometry, then minimize |
| `Super+H` | Minimize (hidden `special:minimized` workspace) |
| `Super+Shift+H` | Restore all minimized windows |
| `Super+V` | Toggle floating |
| `Super+F` | Toggle fullscreen |
| `Super+Shift+Left` | Move window to the monitor on the left |
| `Super+Shift+Right` | Move window to the monitor on the right |

`Super+Left` and `Super+Right` use the available monitor work area below the
Serpantinum top bar, while keeping all windows floating. The fallback top bar
height is 32px if Hyprland has not reserved the panel; override it with
`SERPANTINUM_TOP_BAR_HEIGHT` if your bar size differs.
| `Super+LMB drag` | Resize to Ghostty 65×18, then move window |
| `Super+RMB drag` | Resize window |

On the current Ghostty configuration, 65×18 terminal cells correspond to a
660×428 pixel client window. This calibrated size is applied before the mouse
drag begins. The cursor keeps its relative position inside the restored window,
and the result is clamped to the usable monitor area below the top bar.
Hyprland's automatic cursor warp to the window center is disabled.

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

* Repeated `Super+Down` walks backwards through the window states and finally
  minimizes the window. `Super+H` minimizes it immediately.
* Hyprland has no native minimize; Serpantinum uses a hidden special
  workspace (official Hyprland pattern) and restores windows with
  `Super+Shift+H`.
* Alt+Tab uses the Quickshell-based Hypr App Switcher installed by `./install.sh`.
  It places the selected window above every other window on its workspace and
  lowers the others, without changing their geometry. It never copies
  fullscreen, position or size from one window to another. A maximized-intent tag is kept
  per window because Hyprland exposes only one active maximized slot per
  workspace; switching between two previously maximized windows restores each
  window's own maximized state. Live captures
  are intentionally disabled to avoid Qt/OpenGL freezes on Wayland/NVIDIA;
  the switcher uses static application icons and a five-second safety timeout.
