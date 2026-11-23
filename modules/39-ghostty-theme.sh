#!/usr/bin/env bash
# 39 — Optional Ghostty palette synchronized with Serpantinum/Matugen.

APPTHEME_ENGINE="$SERP_DATA_DIR/src/scripts/theming/apptheme.py"
GHOSTTY_APP_SPEC="$SERP_DATA_DIR/src/assets/matugen/apps/ghostty/app.json"
GHOSTTY_THEME_MARKER="$SERP_STATE_DIR/ghostty-theme-initialized"

if ! command -v ghostty >/dev/null 2>&1; then
    log_skip "theme Ghostty prepare; Ghostty n'est pas encore installe"
    return 0
fi

if [[ ! -f "$APPTHEME_ENGINE" ]]; then
    log_warn "moteur de themes Serpantinum absent: integration Ghostty non appliquee"
    return 0
fi

if [[ ! -f "$GHOSTTY_APP_SPEC" ]]; then
    log_warn "cette version de Serpantinum ne fournit pas encore le theme Ghostty"
    return 0
fi

# Enable only on first installation. Later installer runs preserve an explicit
# `serpantinum set theme app ghostty off` choice.
if [[ ! -e "$GHOSTTY_THEME_MARKER" ]]; then
    if command -v serpantinum >/dev/null 2>&1; then
        if serpantinum set theme app ghostty on; then
            mkdir -p "$(dirname "$GHOSTTY_THEME_MARKER")"
            date -u +%Y-%m-%dT%H:%M:%SZ > "$GHOSTTY_THEME_MARKER"
            log_ok "theme Ghostty synchronise avec Serpantinum"
        else
            log_warn "activation automatique du theme Ghostty impossible"
        fi
    else
        log_warn "CLI Serpantinum absente: active avec 'serpantinum set theme app ghostty on'"
    fi
else
    log_skip "choix du theme Ghostty conserve"
fi

log_ok "theme Ghostty synchronisable (on/off/toggle via la CLI Serpantinum)"

# Refresh the shell palette too, so Ghostty and the top bar change together
# immediately instead of waiting for the next Serpantinum reload.
if command -v serpantinum >/dev/null 2>&1; then
    serpantinum trigger theme reload >/dev/null 2>&1 || \
        log_warn "rechargement des couleurs de la barre impossible"
fi
