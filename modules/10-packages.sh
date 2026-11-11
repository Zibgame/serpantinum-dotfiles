#!/usr/bin/env bash
# 10 — Install only the missing packages declared in dependencies/<family>.txt.
# The family (arch, debian, fedora, suse, none) is detected by lib/detect.sh.

if [[ "${SERP_SKIP_PACKAGES:-0}" -eq 1 ]]; then
    log_skip "installation des paquets ignoree (--no-packages)"
    return 0
fi

if [[ "$SERP_PKG_FAMILY" == "none" || -z "$SERP_PKG_CMD" ]]; then
    log_skip "paquets ignores: distribution non reconnue ou liste absente"
    return 0
fi

mapfile -t SERP_PACKAGES < <(grep -vE '^[[:space:]]*(#|$)' "$SERP_DEPS_FILE")

if (( ${#SERP_PACKAGES[@]} == 0 )); then
    log_skip "aucune dependance declaree"
    return 0
fi

# Debian: refresh the package cache once if it is empty or stale, otherwise
# every apt-cache check fails on a fresh system.
if [[ "$SERP_PKG_FAMILY" == "debian" ]] && ! apt-cache show git >/dev/null 2>&1; then
    log_info "mise a jour de la liste des paquets (apt-get update)"
    sudo_run apt-get update -qq || log_warn "apt-get update a echoue — les checks peuvent donner de faux negatifs"
fi

# Fedora/SUSE: refresh repository metadata for the availability checks.
if [[ "$SERP_PKG_FAMILY" == "fedora" ]] && ! dnf -q list available git >/dev/null 2>&1; then
    log_info "rafraichissement des depots (makecache)"
    sudo_run dnf -q makecache 2>/dev/null || true
fi

missing=()
unavailable=()
for pkg in "${SERP_PACKAGES[@]}"; do
    if pkg_installed "$pkg"; then
        continue
    fi
    if pkg_available "$pkg"; then
        missing+=("$pkg")
    else
        unavailable+=("$pkg")
    fi
done

if (( ${#unavailable[@]} > 0 )); then
    log_warn "paquets absents des depots (ignores): ${unavailable[*]}"
fi

if (( ${#missing[@]} == 0 )); then
    log_skip "toutes les dependances sont deja installees"
    return 0
fi

log_info "paquets manquants: ${missing[*]}"
pkg_install "${missing[@]}"
log_ok "dependances installees"
