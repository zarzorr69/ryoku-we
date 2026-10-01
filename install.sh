#!/usr/bin/env bash
set -Eeuo pipefail

# Ryoku-WE bootstrap installer
# - Detects many Linux package managers
# - Installs missing native dependencies where package mappings are known
# - Uses upstream we-layerd build instructions
# - Installs/updates Rust through rustup when the system toolchain is too old
# - Installs Ryoku automatically only on families supported by Ryoku's own installer
#
# Environment overrides:
#   RYOKU_WE_BRANCH=main
#   RYOKU_WE_SKIP_DEPS=1
#   RYOKU_WE_SKIP_RYOKU=1
#   RYOKU_WE_SKIP_WE_LAYERD=1
#   RYOKU_WE_FORCE_WE_BUILD=1

REPO="zarzorr69/ryoku-we"
BRANCH="${RYOKU_WE_BRANCH:-main}"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

RYOKU_INSTALL_URL="https://raw.githubusercontent.com/ryoku-dev/ryoku/main/ryoku-shell-installer/install.sh"
WE_REPO="https://github.com/Aromatic05/we-layerd.git"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ryoku-we"
WE_SRC="${CACHE_DIR}/we-layerd"

TMP="$(mktemp -t Ryoku-WE.XXXXXX)"
trap 'rm -f "$TMP"' EXIT

say()  { printf '%s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

[[ "$(uname -s)" == "Linux" ]] || die "Ryoku-WE only supports Linux."
[[ "${EUID}" -ne 0 ]] || die "Run this as your normal user, not root."

ensure_sudo() {
    have sudo || die "sudo is required to install system packages."
}

detect_pm() {
    if have pacman; then
        PM="pacman"
        PM_CMD="pacman"
    elif have apt-get; then
        PM="apt"
        PM_CMD="apt-get"
    elif have dnf5; then
        PM="dnf"
        PM_CMD="dnf5"
    elif have dnf; then
        PM="dnf"
        PM_CMD="dnf"
    elif have yum; then
        PM="yum"
        PM_CMD="yum"
    elif have zypper; then
        PM="zypper"
        PM_CMD="zypper"
    elif have xbps-install; then
        PM="xbps"
        PM_CMD="xbps-install"
    elif have apk; then
        PM="apk"
        PM_CMD="apk"
    elif have emerge; then
        PM="emerge"
        PM_CMD="emerge"
    elif have eopkg; then
        PM="eopkg"
        PM_CMD="eopkg"
    elif have swupd; then
        PM="swupd"
        PM_CMD="swupd"
    elif have urpmi; then
        PM="urpmi"
        PM_CMD="urpmi"
    elif have slackpkg; then
        PM="slackpkg"
        PM_CMD="slackpkg"
    elif have nix; then
        PM="nix"
        PM_CMD="nix"
    elif have guix; then
        PM="guix"
        PM_CMD="guix"
    elif have brew; then
        PM="brew"
        PM_CMD="brew"
    elif have pkg; then
        PM="pkg"
        PM_CMD="pkg"
    elif have opkg; then
        PM="opkg"
