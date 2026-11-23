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

# Dans VirtualBox, utiliser Vulkan via Lavapipe. Cela conserve les effets Qt
# natifs (masques, arrondis et animations) sans dependre de l'EGL de la VM.
export QT_QPA_PLATFORM=wayland

is_virtualbox=0
if command -v systemd-detect-virt >/dev/null 2>&1 &&
   [[ "$(systemd-detect-virt --vm 2>/dev/null || true)" == "oracle" ]]; then
    is_virtualbox=1
elif [[ -r /sys/class/dmi/id/product_name ]] &&
     grep -qi 'virtualbox' /sys/class/dmi/id/product_name; then
    is_virtualbox=1
fi

if (( is_virtualbox )); then
    lavapipe_icd=""
    for candidate in \
        /usr/share/vulkan/icd.d/lvp_icd*.json \
        /etc/vulkan/icd.d/lvp_icd*.json \
        /usr/share/vulkan/icd.d/lavapipe_icd*.json \
        /etc/vulkan/icd.d/lavapipe_icd*.json; do
        if [[ -f "$candidate" ]]; then
            lavapipe_icd="$candidate"
            break
        fi
    done

    if [[ -n "$lavapipe_icd" ]]; then
        unset QT_QUICK_BACKEND
        export QSG_RHI_BACKEND=vulkan
        export VK_DRIVER_FILES="$lavapipe_icd"
        echo "Serpantinum: rendu VirtualBox Vulkan/Lavapipe"
    else
        export QT_QUICK_BACKEND=software
        unset QSG_RHI_BACKEND VK_DRIVER_FILES
        echo "AVERTISSEMENT : Lavapipe absent, rendu Qt software limite" >&2
    fi
fi

exec serpantinumd start
