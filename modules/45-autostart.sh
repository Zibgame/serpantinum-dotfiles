#!/usr/bin/env bash
# 45 — Enable session-aware Serpantinum autostart for the current user.

mkdir -p "$HOME/.local/bin" "$HOME/.config/systemd/user"

link_config "$SERP_ROOT/bin/serpantinum-autostart" \
    "$HOME/.local/bin/serpantinum-autostart"
link_config "$SERP_ROOT/config/systemd/user/serpantinum-dotfiles-autostart.service" \
    "$HOME/.config/systemd/user/serpantinum-dotfiles-autostart.service"

# Install the service only once the official shell is available.
if [[ ! -x "$SERP_DATA_DIR/bin/serpantinumd" ]]; then
    log_skip "Autostart ignore: Serpantinum officiel non installe"
    return 0
fi

if ! command -v systemctl >/dev/null 2>&1; then
    log_skip "watcher systemd ignore: systemctl absent (autostart Hyprland conserve)"
    return 0
fi

if ! systemctl --user daemon-reload >/dev/null 2>&1; then
    log_warn "watcher systemd ignore: session utilisateur systemd indisponible"
    return 0
fi
if ! systemctl --user enable serpantinum-dotfiles-autostart.service >/dev/null 2>&1; then
    log_warn "activation du watcher systemd impossible (autostart Hyprland conserve)"
    return 0
fi
if ! systemctl --user restart serpantinum-dotfiles-autostart.service >/dev/null 2>&1; then
    log_warn "demarrage du watcher systemd impossible (il sera retente a la prochaine session)"
    return 0
fi
log_ok "Service d'autostart active (systemd utilisateur)"
