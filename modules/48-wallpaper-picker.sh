#!/usr/bin/env bash
# 48 — Wallpaper picker: restore the complete upstream visual effects.
#
# Older installer revisions disabled the thumbnail layer under VirtualBox
# because QT_QUICK_BACKEND=software cannot render ShaderEffect/MultiEffect.
# The launchers now use Vulkan through Mesa Lavapipe instead, so the original
# layer can stay enabled and Serpantinum keeps its masks, rounded corners,
# complete gallery and native animations.

WallpaperPickerNative_restore() {
    local picker="$SERP_DATA_DIR/src/quickshell/wallpaper/WallpaperPicker.qml"
    if [[ ! -f "$picker" ]]; then
        log_skip "wallpaper picker ignore: Serpantinum officiel non installe"
        return 0
    fi

    if ! grep -Fq 'serpSoftwareRender' "$picker"; then
        if grep -Fq 'layer.enabled: true' "$picker"; then
            log_ok "wallpaper picker natif deja actif"
        else
            log_warn "wallpaper picker non modifie: structure upstream inconnue"
        fi
        return 0
    fi

    local is_virtualbox=0 candidate lavapipe_icd=""
    if command -v systemd-detect-virt >/dev/null 2>&1 &&
       [[ "$(systemd-detect-virt --vm 2>/dev/null || true)" == "oracle" ]]; then
        is_virtualbox=1
    elif [[ -r /sys/class/dmi/id/product_name ]] &&
         grep -qi 'virtualbox' /sys/class/dmi/id/product_name; then
        is_virtualbox=1
    fi

    if (( is_virtualbox )); then
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
        if [[ -z "$lavapipe_icd" ]]; then
            log_warn "Lavapipe absent: ancien fallback du picker conserve"
            return 0
        fi
    fi

    local py=""
    if command -v python3 >/dev/null 2>&1; then
        py="python3"
    elif command -v python >/dev/null 2>&1; then
        py="python"
    fi
    if [[ -z "$py" ]]; then
        log_warn "python introuvable: restauration du picker natif ignoree"
        return 0
    fi

    if ! "$py" - "$picker" <<'PYEOF'
import re
import sys

path = sys.argv[1]
src = open(path, encoding="utf-8").read()

pattern = re.compile(
    r'                        readonly property bool serpSoftwareRender: Quickshell\.env\("QT_QUICK_BACKEND"\) === "software"\n'
    r'                        layer\.enabled: !serpSoftwareRender\n'
    r'                        clip: serpSoftwareRender\n'
)
new, count = pattern.subn("                        layer.enabled: true\n", src)
if count != 1:
    print("ancien patch du picker non reconnu (%d correspondances)" % count)
    sys.exit(2)

open(path, "w", encoding="utf-8").write(new)
print("restored")
PYEOF
    then
        log_warn "restauration du picker natif non appliquee"
        return 0
    fi

    log_ok "wallpaper picker natif restaure (arrondis et animations)"

    if pgrep -f 'quickshell -p' >/dev/null 2>&1 && [[ -x "$SERP_UPSTREAM_CLI" ]]; then
        "$SERP_UPSTREAM_CLI" restart >/dev/null 2>&1 || true
        log_ok "shell Serpantinum relance avec le picker natif"
    fi
}

WallpaperPickerNative_restore
