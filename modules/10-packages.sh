#!/usr/bin/env bash
# 10 — Install only the missing Arch packages declared in dependencies/arch.txt.

if [[ "${SERP_SKIP_PACKAGES:-0}" -eq 1 ]]; then
    log_skip "installation des paquets ignoree (--no-packages)"
    return 0
fi

mapfile -t SERP_PACKAGES < <(grep -vE '^[[:space:]]*(#|$)' "$SERP_ROOT/dependencies/arch.txt")

if (( ${#SERP_PACKAGES[@]} == 0 )); then
    log_skip "aucune dependance declaree"
    return 0
fi

missing=()
for pkg in "${SERP_PACKAGES[@]}"; do
    if ! pacman -Qq "$pkg" >/dev/null 2>&1; then
        missing+=("$pkg")
    fi
done

if (( ${#missing[@]} == 0 )); then
    log_skip "toutes les dependances sont deja installees"
    return 0
fi

log_info "paquets manquants: ${missing[*]}"
sudo_run pacman -S --needed --noconfirm "${missing[@]}"
log_ok "dependances installees"
