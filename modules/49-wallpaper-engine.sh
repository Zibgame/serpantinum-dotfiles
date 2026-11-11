#!/usr/bin/env bash
# 49 — Wallpaper engine: keep full-resolution images sharp.
#
# Upstream asks Qt to decode wallpapers into a box exactly matching the
# monitor.  With PreserveAspectCrop, a source whose aspect ratio differs from
# the monitor is first fitted inside that box and is then enlarged again to
# cover it.  A 16:10 wallpaper on a 16:9 display is therefore needlessly
# upscaled and looks pixelated.  Let Qt retain the source resolution; the
# display crop then only downsamples it.
#
# Idempotent: a marker property detects previous runs.

WallpaperEngineFix_apply() {
    local engine="$SERP_DATA_DIR/src/quickshell/wallpaper/WallpaperEngine.qml"
    if [[ ! -f "$engine" ]]; then
        log_skip "moteur wallpaper ignore: Serpantinum officiel non installe"
        return 0
    fi

    if grep -Fq 'serpFullQualityWallpaper' "$engine"; then
        log_ok "moteur wallpaper deja en pleine qualite"
        return 0
    fi

    local py=""
    if command -v python3 >/dev/null 2>&1; then
        py="python3"
    elif command -v python >/dev/null 2>&1; then
        py="python"
    fi
    if [[ -z "$py" ]]; then
        log_warn "python introuvable: correction qualite wallpaper ignoree"
        return 0
    fi

    if ! "$py" - "$engine" <<'PYEOF'
import re
import sys

path = sys.argv[1]
src = open(path, encoding="utf-8").read()

if "serpFullQualityWallpaper" in src:
    sys.exit(0)

marker_pattern = "                property string currentWallpaperPath: \"\"\n"
marker_replacement = (
    marker_pattern
    + "                readonly property bool serpFullQualityWallpaper: true\n"
)
if src.count(marker_pattern) != 1:
    print("point d'insertion du marqueur introuvable")
    sys.exit(2)
src = src.replace(marker_pattern, marker_replacement, 1)

size_pattern = re.compile(
    r"\n                            sourceSize\.width: parent\.width > 0 \? Math\.ceil\(parent\.width \* \(Screen\.devicePixelRatio \|\| 1\)\) : 0"
    r"\n                            sourceSize\.height: parent\.height > 0 \? Math\.ceil\(parent\.height \* \(Screen\.devicePixelRatio \|\| 1\)\) : 0"
)
src, count = size_pattern.subn("", src)
if count != 2:
    print("tailles de decodage du moteur non trouvees (%d correspondances)" % count)
    sys.exit(2)

open(path, "w", encoding="utf-8").write(src)
print("patched")
PYEOF
    then
        log_warn "correction qualite wallpaper non appliquee (voir message ci-dessus)"
        return 0
    fi

    log_ok "wallpapers conserves en pleine resolution"

    # Apply immediately when the shell is already running.
    if pgrep -f 'quickshell -p' >/dev/null 2>&1 && [[ -x "$SERP_UPSTREAM_CLI" ]]; then
        "$SERP_UPSTREAM_CLI" restart >/dev/null 2>&1 || true
        log_ok "shell Serpantinum relance avec le moteur wallpaper repare"
    fi
}

WallpaperEngineFix_apply
