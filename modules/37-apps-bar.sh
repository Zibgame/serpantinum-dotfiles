#!/usr/bin/env bash
# 37 — Replace the workspace indicator with clickable running applications.

SERP_QS_DIR="$SERP_DATA_DIR/src/quickshell"
SERP_BAR_REGISTRY="$SERP_QS_DIR/bar/BarModuleRegistry.qml"
SERP_APPS_FACE="$SERP_QS_DIR/bar/faces/apps/AppsFace.qml"
SERP_APPS_PATCH="$SERP_ROOT/patches/serpantinum-apps-bar.patch"

if [[ ! -f "$SERP_BAR_REGISTRY" ]]; then
    log_skip "barre Serpantinum absente: module applications ignore"
    return 0
fi

install_asset \
    "$SERP_ROOT/config/serpantinum/apps-bar/AppsFace.qml" \
    "$SERP_APPS_FACE"

if grep -Fq 'face: "faces/apps/AppsFace.qml"' "$SERP_BAR_REGISTRY"; then
    log_skip "applications ouvertes deja affichees dans la barre"
else
    patch -d "$SERP_QS_DIR" -p1 --forward --silent < "$SERP_APPS_PATCH" || \
        die "impossible d'appliquer le module applications a la barre Serpantinum"
    log_ok "workspaces remplaces par les applications ouvertes"
fi

if command -v serpantinum >/dev/null 2>&1 && pgrep -f 'quickshell.*serpantinum/src/quickshell' >/dev/null 2>&1; then
    serpantinum reload || log_warn "rechargement Serpantinum impossible; reconnecte-toi"
fi
