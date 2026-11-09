#!/usr/bin/env bash
# 00 — Preflight: connectivity and required directories.

if [[ "${SERP_SKIP_PACKAGES:-0}" -eq 0 ]]; then
    if curl -fsS --max-time 10 https://github.com >/dev/null 2>&1; then
        log_ok "acces reseau (GitHub) OK"
    else
        log_warn "GitHub injoignable — oh-my-zsh et les plugins Vim risquent d'echouer"
    fi
fi

log_ok "repertoires d'etat: $SERP_STATE_DIR"
log_ok "repertoires de donnees: $SERP_DATA_DIR"
