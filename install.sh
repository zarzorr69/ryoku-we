#!/usr/bin/env bash
set -Eeuo pipefail

REPO="zarzorr69/ryoku-we"
BRANCH="${RYOKU_WE_BRANCH:-main}"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
RYOKU_INSTALL_URL="https://raw.githubusercontent.com/ryoku-dev/ryoku/main/ryoku-shell-installer/install.sh"
WE_REPO="https://github.com/Aromatic05/we-layerd.git"

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/ryoku-we"
WE_SRC="$CACHE/we-layerd"
TMP="$(mktemp -t Ryoku-WE.XXXXXX)"
trap 'rm -f "$TMP"' EXIT

say(){ printf '%s\n' "$*"; }
warn(){ printf 'WARNING: %s\n' "$*" >&2; }
die(){ printf 'ERROR: %s\n' "$*" >&2; exit 1; }
have(){ command -v "$1" >/dev/null 2>&1; }

[[ "$(uname -s)" == "Linux" ]] || die "Ryoku-WE supports Linux only."
[[ "$EUID" -ne 0 ]] || die "Run this installer as your normal user, not root."

ensure_sudo(){ have sudo || die "sudo is required for missing system packages."; }

detect_pm() {
    if have pacman; then PM=pacman
    elif have apt-get; then PM=apt
    elif have dnf5; then PM=dnf
    elif have dnf; then PM=dnf
    elif have yum; then PM=yum
    elif have zypper; then PM=zypper
    elif have xbps-install; then PM=xbps
    elif have apk; then PM=apk
    elif have emerge; then PM=emerge
    elif have eopkg; then PM=eopkg
    elif have swupd; then PM=swupd
    elif have urpmi; then PM=urpmi
    elif have slackpkg; then PM=slackpkg
    elif have nix; then PM=nix
    elif have guix; then PM=guix
    elif have brew; then PM=brew
    elif have pkg; then PM=pkg
    elif have opkg; then PM=opkg
    else PM=unknown
    fi
}

pacman_install() {
    local repo=() aur=() p
    for p in "$@"; do
        if pacman -T "$p" >/dev/null 2>&1; then
            if pacman -Si "$p" >/dev/null 2>&1; then repo+=("$p"); else aur+=("$p"); fi
        fi
    done
    if ((${#repo[@]})); then
        ensure_sudo
        sudo pacman -S --needed --noconfirm "${repo[@]}"
    fi
    if ((${#aur[@]})); then
        if have yay; then yay -S --needed --noconfirm "${aur[@]}"
        elif have paru; then paru -S --needed --noconfirm "${aur[@]}"
        else
            printf 'Missing AUR packages:\n' >&2
            printf '  %s\n' "${aur[@]}" >&2
            die "Install yay/paru, then rerun."
        fi
    fi
}

best_effort() {
    local p
    for p in "$@"; do
        case "$PM" in
            zypper) sudo zypper --non-interactive install -y "$p" >/dev/null 2>&1 || warn "zypper: $p unavailable" ;;
            xbps) sudo xbps-install -Sy "$p" >/dev/null 2>&1 || warn "xbps: $p unavailable" ;;
            apk) sudo apk add "$p" >/dev/null 2>&1 || warn "apk: $p unavailable" ;;
            emerge) sudo emerge --noreplace "$p" >/dev/null 2>&1 || warn "emerge: $p unavailable" ;;
            eopkg) sudo eopkg install -y "$p" >/dev/null 2>&1 || warn "eopkg: $p unavailable" ;;
            urpmi) sudo urpmi --auto "$p" >/dev/null 2>&1 || warn "urpmi: $p unavailable" ;;
            slackpkg) sudo slackpkg -batch=on -default_answer=y install "$p" >/dev/null 2>&1 || warn "slackpkg: $p unavailable" ;;
            guix) guix install "$p" >/dev/null 2>&1 || warn "guix: $p unavailable" ;;
            brew) brew list "$p" >/dev/null 2>&1 || brew install "$p" >/dev/null 2>&1 || warn "brew: $p unavailable" ;;
            pkg) sudo pkg install -y "$p" >/dev/null 2>&1 || warn "pkg: $p unavailable" ;;
            opkg) sudo opkg install "$p" >/dev/null 2>&1 || warn "opkg: $p unavailable" ;;
        esac
    done
}

install_core() {
    say "==> Checking core dependencies..."
    case "$PM" in
        pacman)
            pacman_install curl ca-certificates python git gcc cmake pkgconf procps-ng
            ;;
        apt)
            ensure_sudo
