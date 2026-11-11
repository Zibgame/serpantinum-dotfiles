#!/usr/bin/env bash
# 48 — Wallpaper picker: compatibility with the Qt Quick software renderer.
#
# VirtualBox sessions run the shell with QT_QUICK_BACKEND=software (the
# GL stack of the guest is unreliable). The software renderer does not
# support ShaderEffect/MultiEffect, so upstream's rounded-corner mask
# (layer.enabled + MultiEffect on the picker thumbnails) renders as
# nothing and the wallpaper gallery appears empty.
#
# The fix keeps the GPU path untouched on real hardware and disables the
# layer (falling back to clip-based rendering) only when the software
# backend is active. Idempotent: a marker property detects previous runs.

PickerFix_pick() {
    local picker="$SERP_DATA_DIR/src/quickshell/wallpaper/WallpaperPicker.qml"
    if [[ ! -f "$picker" ]]; then
        log_skip "wallpaper picker ignore: Serpantinum officiel non installe"
        return 0
    fi

    if grep -Fq 'serpSoftwareRender' "$picker"; then
        log_ok "wallpaper picker deja compatible rendu software"
        return 0
    fi

    local py=""
    if command -v python3 >/dev/null 2>&1; then
        py="python3"
    elif command -v python >/dev/null 2>&1; then
        py="python"
    fi
    if [[ -z "$py" ]]; then
        log_warn "python introuvable: patch du wallpaper picker ignore"
        return 0
    fi

    if ! "$py" - "$picker" <<'PYEOF'
import re
import sys

path = sys.argv[1]
src = open(path, encoding="utf-8").read()

if "serpSoftwareRender" in src:
    sys.exit(0)

pattern = re.compile(
    r"(                    Item \{\n"
    r"                        anchors\.fill: parent\n)"
    r"                        layer\.enabled: (?:true|false)\n"
    r"(?:                        clip: (?:true|false|serpSoftwareRender)\n)?"
    r"(                        layer\.effect: MultiEffect \{\n"
    r"                            maskEnabled: true\n"
    r"                            maskSource: paperMask)"
)

replacement = (
    r"\1"
    "                        readonly property bool serpSoftwareRender: Quickshell.env(\"QT_QUICK_BACKEND\") === \"software\"\n"
    "                        layer.enabled: !serpSoftwareRender\n"
    "                        clip: serpSoftwareRender\n"
    r"\2"
)

new, count = pattern.subn(replacement, src)
if count != 1:
    print("pattern du picker non trouve (%d correspondances), upstream a peut-etre change" % count)
    sys.exit(2)

open(path, "w", encoding="utf-8").write(new)
print("patched")
PYEOF
    then
        log_warn "patch du wallpaper picker non applique (voir message ci-dessus)"
        return 0
    fi

    log_ok "wallpaper picker compatible rendu software (VirtualBox)"

    # Apply immediately when the shell is already running.
    if pgrep -f 'quickshell -p' >/dev/null 2>&1 && [[ -x "$SERP_UPSTREAM_CLI" ]]; then
        "$SERP_UPSTREAM_CLI" restart >/dev/null 2>&1 || true
        log_ok "shell Serpantinum relance avec le picker repare"
    fi
}

PickerFix_pick
