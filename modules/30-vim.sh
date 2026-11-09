#!/usr/bin/env bash
# 30 — Vim: vim-plug, .vimrc and plugins.

if [[ ! -f "$HOME/.vim/autoload/plug.vim" ]]; then
    log_info "installation de vim-plug"
    if curl -fsSL --create-dirs -o "$HOME/.vim/autoload/plug.vim" \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim; then
        log_ok "vim-plug installe"
    else
        log_warn "echec du telechargement de vim-plug"
    fi
else
    log_skip "vim-plug deja present"
fi

link_config "$SERP_ROOT/config/vim/.vimrc" "$HOME/.vimrc"

if [[ "${SERP_SKIP_VIM:-0}" -eq 1 ]]; then
    log_skip "plugins Vim ignores (--no-vim)"
    return 0
fi

if command -v vim >/dev/null 2>&1; then
    log_info "installation/mise a jour des plugins Vim (peut prendre quelques minutes)"
    if vim -N -u "$HOME/.vimrc" -es +'PlugInstall --sync' +qa >/dev/null 2>&1; then
        log_ok "plugins Vim installes"
    else
        log_warn "PlugInstall a signale une erreur (verifie avec 'vim +PlugStatus')"
    fi
else
    log_warn "vim introuvable"
fi
