#!/usr/bin/env bash
# Serpantinum — lancement robuste du shell officiel.
# Fonctionne depuis Hyprland (exec-once), depuis tty1 ou depuis un shell SSH :
# il reconstruit lui-meme l'environnement Hyprland/Wayland manquant.

mkdir -p "$HOME/.local/bin"
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

export XDG_RUNTIME_DIR="/run/user/$(id -u)"

export HYPRLAND_INSTANCE_SIGNATURE="${HYPRLAND_INSTANCE_SIGNATURE:-$(
    hyprctl instances |
    awk '/^instance / {gsub(/:/, "", $2); print $2; exit}'
)}"

export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-$(
    hyprctl instances |
    awk '/wl socket:/ {print $3; exit}'
)}"

export XDG_SESSION_TYPE=wayland

# Attendre que Wayland soit disponible
for i in {1..30}; do
    test -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" && break
    sleep 1
done

test -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" || {
    echo "ERREUR : session Wayland introuvable"
    exit 1
}

# Lancer Serpantinum avec le rendu logiciel
export QT_QPA_PLATFORM=wayland
export QT_QUICK_BACKEND=software

exec serpantinumd start
