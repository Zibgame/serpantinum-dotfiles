#!/usr/bin/env bash
# Distribution detection for the Serpantinum installer.
#
# Serpantinum targets Hyprland on any GNU/Linux distribution. Package
# installation is adapted to the detected family:
#
#   arch   — Arch, BlackArch, EndeavourOS, Manjaro, CachyOS, Garuda, Artix...
#   debian — Debian, Ubuntu, Kali, Parrot, Mint, Pop!_OS...
#   fedora — Fedora, Nobara, RHEL, CentOS Stream, Rocky, Alma...
#   suse   — openSUSE Leap / Tumbleweed
#   none   — unknown distribution: dotfiles are installed, packages are skipped.

SERP_PKG_FAMILY="none"
SERP_PKG_CMD=""
SERP_DEPS_FILE=""

# True when $2 is one of the comma/whitespace separated tokens in $1.
_serp_token_in() {
    local list="$1" token="$2" t
    for t in ${list//[',']/ } ; do
        [[ "$t" == "$token" ]] && return 0
    done
    return 1
}

# Classify a distribution from its ID / ID_LIKE fields.
_serp_classify() {
    local id="$1" like="${2:-}"
    if _serp_token_in "$id" arch || _serp_token_in "$like" arch \
        || _serp_token_in "$like" manjaro || _serp_token_in "$like" endeavouros \
        || _serp_token_in "$like" blackarch; then
        echo arch
    elif _serp_token_in "$id" debian || _serp_token_in "$like" debian \
        || _serp_token_in "$like" ubuntu || _serp_token_in "$like" kali; then
        echo debian
    elif _serp_token_in "$id" fedora || _serp_token_in "$like" fedora \
        || _serp_token_in "$id" rhel || _serp_token_in "$like" rhel; then
        echo fedora
    elif [[ "$id" == opensuse* || "$id" == *suse* || "$like" == *suse* ]]; then
        echo suse
    elif _serp_token_in "$id" void || _serp_token_in "$like" void; then
        echo void
    else
        echo none
    fi
}

# First available package manager command for the family.
_serp_pkg_cmd() {
    local family="$1"
    case "$family" in
        arch)   for c in pacman pamac paru; do command -v "$c" >/dev/null 2>&1 && { echo "$c"; return 0; } ; done ;;
        debian) for c in apt-get apt;  do command -v "$c" >/dev/null 2>&1 && { echo "$c"; return 0; } ; done ;;
        fedora) for c in dnf dnf5 yum; do command -v "$c" >/dev/null 2>&1 && { echo "$c"; return 0; } ; done ;;
        suse)   for c in zypper;       do command -v "$c" >/dev/null 2>&1 && { echo "$c"; return 0; } ; done ;;
        void)   for c in xbps-install; do command -v "$c" >/dev/null 2>&1 && { echo "$c"; return 0; } ; done ;;
    esac
    return 1
}

detect_environment() {
    [[ -n "${HOME:-}" ]] || die "HOME n'est pas defini"

    if [[ ! -r /etc/os-release ]]; then
        log_warn "Distribution inconnue (/etc/os-release absent): paquets ignores"
        return 0
    fi

    # shellcheck disable=SC1091
    . /etc/os-release
    SERP_PKG_FAMILY="$(_serp_classify "${ID:-}" "${ID_LIKE:-}")"
    SERP_PKG_CMD="$(_serp_pkg_cmd "$SERP_PKG_FAMILY")" || SERP_PKG_CMD=""
    SERP_DEPS_FILE="$SERP_ROOT/dependencies/${SERP_PKG_FAMILY}.txt"

    case "$SERP_PKG_FAMILY" in
        arch)   log_ok "Distribution: ${PRETTY_NAME:-Arch Linux} (famille Arch)" ;;
        debian) log_ok "Distribution: ${PRETTY_NAME:-Debian} (famille Debian)" ;;
        fedora) log_ok "Distribution: ${PRETTY_NAME:-Fedora} (famille Fedora)" ;;
        suse)   log_ok "Distribution: ${PRETTY_NAME:-openSUSE} (famille SUSE)" ;;
        void)   log_ok "Distribution: ${PRETTY_NAME:-Void Linux} (famille Void)" ;;
        none)   log_warn "Distribution non reconnue: ${PRETTY_NAME:-inconnue} — paquets ignores, dotfiles installes quand meme" ;;
    esac

    if [[ -n "$SERP_PKG_CMD" && ! -f "$SERP_DEPS_FILE" ]]; then
        log_warn "aucune liste de paquets pour la famille '$SERP_PKG_FAMILY': $SERP_DEPS_FILE absent — paquets ignores"
        SERP_PKG_CMD=""
    fi

    command -v git >/dev/null 2>&1 || die "git est introuvable"

    if [[ $EUID -ne 0 ]]; then
        command -v sudo >/dev/null 2>&1 || die "sudo est introuvable"
        if [[ -z "${SERP_SUDO:-}" ]] && ! sudo -n true 2>/dev/null; then
            log_warn "sudo demandera un mot de passe (lance 'sudo -v' avant pour une installation non interactive)"
        fi
    fi

    if command -v Hyprland >/dev/null 2>&1; then
        log_ok "Hyprland: $(Hyprland --version 2>/dev/null | head -n1 || echo present)"
    elif [[ "$SERP_PKG_FAMILY" == "arch" || "$SERP_PKG_FAMILY" == "void" ]]; then
        log_warn "Hyprland absent: il sera installe par le module paquets"
    else
        log_warn "Hyprland absent: installe-le avec le gestionnaire de paquets de ta distribution"
    fi

    log_info "Utilisateur: ${USER:-$(id -un)} — HOME=$HOME"
}
