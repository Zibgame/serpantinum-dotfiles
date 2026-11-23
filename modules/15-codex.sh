#!/usr/bin/env bash
# 15 — OpenAI Codex CLI: user-local npm installation.

if [[ "${SERP_SKIP_CODEX:-0}" -eq 1 ]]; then
    log_skip "Codex ignore (--no-codex)"
    return 0
fi

if [[ "${SERP_SKIP_PACKAGES:-0}" -eq 1 ]]; then
    log_skip "Codex ignore (--no-packages)"
    return 0
fi

CODEX_BIN="$(command -v codex 2>/dev/null || true)"
if [[ -z "$CODEX_BIN" && -x "$HOME/.npm-global/bin/codex" ]]; then
    CODEX_BIN="$HOME/.npm-global/bin/codex"
fi
if [[ -n "$CODEX_BIN" ]]; then
    log_skip "Codex deja installe: $($CODEX_BIN --version 2>/dev/null || echo present)"
    return 0
fi

if ! command -v npm >/dev/null 2>&1; then
    log_warn "npm introuvable: installation de Codex ignoree"
    return 0
fi

mkdir -p "$HOME/.npm-global"
log_info "installation de Codex dans ~/.npm-global"
if npm install --global --prefix "$HOME/.npm-global" @openai/codex@latest; then
    log_ok "Codex installe: $($HOME/.npm-global/bin/codex --version)"
else
    log_warn "installation de Codex echouee (verifie la connexion npm)"
fi
