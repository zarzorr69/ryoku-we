#!/usr/bin/env bash
set -Eeuo pipefail

REPO="zarzorr69/ryoku-we"
BRANCH="${RYOKU_WE_BRANCH:-main}"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

WE_REPO="https://github.com/Aromatic05/we-layerd.git"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ryoku-we"
WE_SRC="${CACHE_DIR}/we-layerd"

TMP="$(mktemp -t Ryoku-WE.XXXXXX)"
trap 'rm -f "$TMP"' EXIT

say() { printf '%s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[[ "$(uname -s)" == "Linux" ]] || die "Ryoku-WE only supports Linux."
[[ "${EUID}" -ne 0 ]] || die "Do not run this installer as root."

if have pacman; then
    PM="pacman"
elif have apt-get; then
    PM="apt"
elif have dnf; then
    PM="dnf"
else
    die "Unsupported package manager. Supported: pacman, apt-get, dnf."
fi

say "Ryoku-WE dependency bootstrap"
say "============================"
say "Package manager: $PM"
say

ensure_sudo() {
    have sudo || die "sudo is required to install missing system packages."
}

arch_install() {
    local repo_pkgs=()
    local aur_pkgs=()
    local pkg

    for pkg in "$@"; do
        pacman -Qq "$pkg" >/dev/null 2>&1 && continue

        if pacman -Si "$pkg" >/dev/null 2>&1; then
            repo_pkgs+=("$pkg")
        else
            aur_pkgs+=("$pkg")
        fi
    done

    if ((${#repo_pkgs[@]})); then
        ensure_sudo
        say "==> Installing missing pacman packages..."
        sudo pacman -S --needed --noconfirm "${repo_pkgs[@]}"
    fi

    if ((${#aur_pkgs[@]})); then
        if have yay; then
            say "==> Installing missing AUR packages with yay..."
            yay -S --needed --noconfirm "${aur_pkgs[@]}"
        elif have paru; then
            say "==> Installing missing AUR packages with paru..."
            paru -S --needed --noconfirm "${aur_pkgs[@]}"
        else
            say "Missing packages not found in configured pacman repos:"
            printf '  %s\n' "${aur_pkgs[@]}"
            die "Install yay/paru or install those packages manually, then rerun."
        fi
    fi
}

install_dependencies() {
    case "$PM" in
        pacman)
            # Current upstream we-layerd Arch build deps + Ryoku-WE runtime tools.
            arch_install \
                curl ca-certificates python git gcc cmake pkgconf procps-ng \
                wayland wayland-protocols libxkbcommon gtk3 xdotool \
                vulkan-headers vulkan-icd-loader mesa libglvnd \
                gstreamer gst-libav gst-plugins-base-libs \
                gst-plugins-bad-libs gst-plugins-good \
                lz4 pango fontconfig freetype2 \
                directx-shader-compiler cef
            ;;

        apt)
            ensure_sudo
            say "==> Installing Debian/Ubuntu dependencies..."
            sudo apt-get update
            sudo apt-get install -y \
                curl ca-certificates python3 git build-essential cmake \
