#!/usr/bin/env bash
# 20 — Zsh: oh-my-zsh, .zshrc, Serpantinum environment, login shell.

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log_info "installation d'oh-my-zsh"
    if git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh" >/dev/null 2>&1; then
        log_ok "oh-my-zsh installe"
    else
        log_warn "echec du clone d'oh-my-zsh (verifie le reseau)"
    fi
else
    log_skip "oh-my-zsh deja present"
fi

link_config "$SERP_ROOT/config/zsh/.zshrc" "$HOME/.zshrc"
link_config "$SERP_ROOT/config/serpantinum/env.sh" "$SERP_CONFIG_DIR/env.sh"

if [[ "${SERP_SKIP_SHELL:-0}" -eq 1 ]]; then
    log_skip "changement de shell ignore (--no-shell)"
    return 0
fi

ZSH_BIN="$(command -v zsh || true)"
if [[ -z "$ZSH_BIN" ]]; then
    log_warn "zsh introuvable: shell de connexion inchange"
elif [[ "$(getent passwd "${USER:-$(id -un)}" | cut -d: -f7)" == "$ZSH_BIN" ]]; then
    log_skip "zsh est deja le shell de connexion"
else
    log_info "passage du shell de connexion a zsh"
    if sudo_run chsh -s "$ZSH_BIN" "${USER:-$(id -un)}"; then
        log_ok "shell de connexion: zsh"
    else
        log_warn "chsh a echoue — lance manuellement: chsh -s $ZSH_BIN"
    fi
fi
