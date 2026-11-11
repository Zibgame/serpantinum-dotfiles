#!/usr/bin/env bash
# Shared helpers for the Serpantinum installer.
# Sourced by install.sh and every module.

if [[ -t 1 ]]; then
    C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'
    C_BLUE=$'\033[34m'; C_GREEN=$'\033[32m'
    C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'; C_DIM=$'\033[2m'
else
    C_RESET=''; C_BOLD=''; C_BLUE=''; C_GREEN=''; C_YELLOW=''; C_RED=''; C_DIM=''
fi

log_step()  { printf '\n%s==>%s %s%s%s\n' "$C_BLUE" "$C_RESET" "$C_BOLD" "$*" "$C_RESET"; }
log_info()  { printf '    %s\n' "$*"; }
log_ok()    { printf '    %s✓%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
log_skip()  { printf '    %s·%s %s\n' "$C_DIM" "$C_RESET" "$*"; }
log_warn()  { printf '    %s!%s %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
log_error() { printf '    %s✗%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; }

die() { log_error "$*"; exit 1; }

# Sudo wrapper. SERP_SUDO can override the command (e.g. "sudo -A" with
# SUDO_ASKPASS for non-interactive installs, or "doas").
sudo_run() {
    if [[ $EUID -eq 0 ]]; then
        "$@"
    else
        # shellcheck disable=SC2086
        ${SERP_SUDO:-sudo} "$@"
    fi
}

# Copy an existing file out of the way before it is replaced.
backup_file() {
    local target="$1"
    [[ -e "$target" || -L "$target" ]] || return 0

    local stamp dir rel
    stamp="$(date +%Y%m%d-%H%M%S)"
    dir="$SERP_STATE_DIR/backups/$stamp"
    rel="${target#"$HOME"/}"
    mkdir -p "$dir/$(dirname "$rel")"
    cp -a "$target" "$dir/$rel"
    log_info "sauvegarde: $target -> $dir/$rel"
}

# Idempotently symlink a repository file into the home directory.
link_config() {
    local src="$1" dst="$2"

    [[ -e "$src" ]] || die "fichier source introuvable: $src"
    mkdir -p "$(dirname "$dst")"

    if [[ -L "$dst" ]]; then
        if [[ "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
            log_skip "deja lie: $dst"
            return 0
        fi
        rm -f "$dst"
    elif [[ -e "$dst" ]]; then
        backup_file "$dst"
        rm -f "$dst"
    fi

    ln -s "$src" "$dst"
    log_ok "lie: $dst -> $src"
}

# Copy a static asset (wallpaper, ...) only when it changed.
install_asset() {
    local src="$1" dst="$2"

    [[ -e "$src" ]] || die "asset introuvable: $src"
    mkdir -p "$(dirname "$dst")"

    if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then
        log_skip "deja present: $dst"
        return 0
    fi

    cp -f "$src" "$dst"
    log_ok "installe: $dst"
}

# Resolve the Hyprland instance signature when running outside the session
# (for example from an SSH shell), so hyprctl works during the install.
hypr_sig() {
    if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        local runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
        if [[ -d "$runtime/hypr" ]]; then
            HYPRLAND_INSTANCE_SIGNATURE="$(ls -1 "$runtime/hypr" 2>/dev/null | head -n1)"
            export HYPRLAND_INSTANCE_SIGNATURE
        fi
    fi
}

# True when Hyprland is reachable from the current shell.
hypr_running() {
    hypr_sig
    command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1
}

hypr_reload() {
    if hypr_running; then
        if hyprctl reload >/dev/null 2>&1; then
            log_ok "Hyprland recharge"
        else
            log_warn "hyprctl reload a echoue (voir le journal Hyprland)"
        fi
    else
        log_info "Hyprland inactif: la configuration sera chargee au prochain demarrage"
    fi
}

# --- Package helpers (family-aware, set by lib/detect.sh) --------------------
# pkg_installed <name>     -> 0 when the package is present.
# pkg_available <name>     -> 0 when the package exists in the repositories.
# pkg_install <names...>   -> install via the family package manager.
pkg_installed() {
    local pkg="$1"
    case "$SERP_PKG_FAMILY" in
        arch)   pacman -Qq "$pkg" >/dev/null 2>&1 ;;
        debian) dpkg-query -W -f='${Status}\n' "$pkg" 2>/dev/null | grep -q "install ok installed" ;;
        fedora) rpm -q "$pkg" >/dev/null 2>&1 ;;
        suse)   rpm -q "$pkg" >/dev/null 2>&1 ;;
        void)   xbps-query "$pkg" >/dev/null 2>&1 ;;
        *)      return 1 ;;
    esac
}

pkg_available() {
    local pkg="$1"
    case "$SERP_PKG_FAMILY" in
        arch)   pacman -Si "$pkg" >/dev/null 2>&1 ;;
        debian) apt-cache show "$pkg" >/dev/null 2>&1 ;;
        fedora) dnf -q list available "$pkg" >/dev/null 2>&1 \
                    || dnf5 -q list available "$pkg" >/dev/null 2>&1 \
                    || yum -q list available "$pkg" >/dev/null 2>&1 ;;
        suse)   zypper -q se -s --match-exact "$pkg" 2>/dev/null | grep -q " | $pkg |" ;;
        void)   xbps-query -R "$pkg" >/dev/null 2>&1 ;;
        *)      return 1 ;;
    esac
}

pkg_install() {
    local pkgs=("$@")
    ((${#pkgs[@]} > 0)) || return 0
    case "$SERP_PKG_FAMILY" in
        arch)   sudo_run pacman -S --needed --noconfirm "${pkgs[@]}" ;;
        debian) sudo_run apt-get install -y "${pkgs[@]}" ;;
        fedora)
            if ! sudo_run dnf install -y "${pkgs[@]}" 2>/dev/null \
               && ! sudo_run dnf5 install -y "${pkgs[@]}" 2>/dev/null; then
                sudo_run yum install -y "${pkgs[@]}"
            fi ;;
        suse)   sudo_run zypper -n install -l "${pkgs[@]}" ;;
        void)   sudo_run xbps-install -Sy "${pkgs[@]}" ;;
        *)      log_warn "aucun gestionnaire de paquets pour installer: ${pkgs[*]}" ; return 1 ;;
    esac
}

is_installed() {
    [[ -f "$SERP_STATE_DIR/installed" ]]
}

mark_installed() {
    date -u +%Y-%m-%dT%H:%M:%SZ > "$SERP_STATE_DIR/installed"
    printf '%s\n' "$SERP_ROOT" > "$SERP_STATE_DIR/source"
}
