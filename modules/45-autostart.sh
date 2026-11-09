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

command -v systemctl >/dev/null 2>&1 || \
    die "systemctl introuvable: service d'autostart impossible"

systemctl --user daemon-reload
systemctl --user enable serpantinum-dotfiles-autostart.service >/dev/null
systemctl --user restart serpantinum-dotfiles-autostart.service
log_ok "Service d'autostart active (systemd utilisateur)"
