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
            sudo apt-get update
            sudo apt-get install -y curl ca-certificates python3 git build-essential cmake pkg-config procps
            ;;
        dnf|yum)
            ensure_sudo
            local cmd=dnf
            have dnf5 && cmd=dnf5
            [[ "$PM" == yum ]] && cmd=yum
            sudo "$cmd" install -y curl ca-certificates python3 git gcc-c++ cmake pkgconf-pkg-config procps-ng
            ;;
        zypper|xbps|apk|emerge|eopkg|urpmi|slackpkg|guix|brew|pkg|opkg)
            [[ "$PM" != guix && "$PM" != brew ]] && ensure_sudo
            best_effort curl python3 git gcc cmake pkg-config
            ;;
        swupd)
            ensure_sudo
            sudo swupd bundle-add c-basic dev-utils || true
            ;;
        nix) : ;;
        unknown) warn "Unknown package manager; assuming core dependencies are already installed." ;;
    esac
    have curl || die "curl is required."
    have git || die "git is required."
}

install_we_deps() {
    say "==> Installing we-layerd build dependencies..."
    case "$PM" in
        pacman)
            pacman_install \
                rustup gcc cmake pkgconf git \
                wayland wayland-protocols libxkbcommon \
                gtk3 xdotool \
                vulkan-headers vulkan-icd-loader mesa libglvnd \
                gstreamer gst-plugins-base-libs \
                lz4 pango fontconfig freetype2 \
                directx-shader-compiler cef
            ;;
        apt)
            ensure_sudo
            sudo apt-get update
            sudo apt-get install -y \
                build-essential cmake pkg-config git curl ca-certificates \
                libwayland-dev wayland-protocols libxkbcommon-dev libgtk-3-dev \
                liblz4-dev libpango1.0-dev libfontconfig1-dev libfreetype-dev \
                libvulkan-dev libgl-dev libdrm-dev libva-dev \
                libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
                libgstreamer-plugins-bad1.0-dev libxdo-dev xdotool patchelf \
                bzip2 xz-utils
            ;;
        dnf|yum)
            ensure_sudo
            local cmd=dnf
            have dnf5 && cmd=dnf5
            [[ "$PM" == yum ]] && cmd=yum
            sudo "$cmd" install -y \
                gcc-c++ cmake pkgconf-pkg-config git curl ca-certificates \
                wayland-devel wayland-protocols-devel libxkbcommon-devel gtk3-devel \
                lz4-devel pango-devel fontconfig-devel freetype-devel \
                vulkan-loader-devel vulkan-headers mesa-libGL-devel \
                libatomic libdrm-devel libva-devel \
                gstreamer1-devel gstreamer1-plugins-base-devel \
                gstreamer1-plugins-bad-free-devel \
                cef cef-devel libxdo-devel xdotool patchelf
            ;;
        nix) return ;;
        *)
            warn "No upstream-native we-layerd recipe exists for $PM."
            warn "Trying common dependency names."
            [[ "$PM" != guix && "$PM" != brew && "$PM" != unknown ]] && ensure_sudo || true
            case "$PM" in
                zypper) best_effort wayland-devel wayland-protocols-devel libxkbcommon-devel gtk3-devel liblz4-devel pango-devel fontconfig-devel freetype2-devel vulkan-devel Mesa-libGL-devel libdrm-devel libva-devel gstreamer-devel gstreamer-plugins-base-devel libXdo-devel xdotool patchelf bzip2 xz ;;
                xbps) best_effort wayland-devel wayland-protocols libxkbcommon-devel gtk+3-devel lz4-devel pango-devel fontconfig-devel freetype-devel Vulkan-Headers Vulkan-Loader mesa-devel libdrm-devel libva-devel gstreamer1-devel gst-plugins-base1-devel gst-plugins-bad1-devel xdotool patchelf ;;
                apk) best_effort wayland-dev wayland-protocols libxkbcommon-dev gtk+3.0-dev lz4-dev pango-dev fontconfig-dev freetype-dev vulkan-headers vulkan-loader-dev mesa-dev libdrm-dev libva-dev gstreamer-dev gst-plugins-base-dev gst-plugins-bad-dev xdotool-dev patchelf ;;
                emerge) best_effort dev-libs/wayland dev-libs/wayland-protocols x11-libs/libxkbcommon x11-libs/gtk+ app-arch/lz4 x11-libs/pango media-libs/fontconfig media-libs/freetype media-libs/vulkan-loader dev-util/vulkan-headers media-libs/mesa x11-libs/libdrm media-libs/libva media-libs/gstreamer media-libs/gst-plugins-base x11-misc/xdotool dev-util/patchelf ;;
                eopkg) best_effort wayland-devel wayland-protocols-devel libxkbcommon-devel gtk3-devel lz4-devel pango-devel fontconfig-devel freetype2-devel vulkan-devel mesa-devel libdrm-devel libva-devel gstreamer-devel gst-plugins-base-devel xdotool patchelf ;;
                guix) best_effort wayland wayland-protocols libxkbcommon gtk+ lz4 pango fontconfig freetype vulkan-headers vulkan-loader mesa libdrm libva gstreamer gst-plugins-base gst-plugins-bad xdotool patchelf ;;
                brew) best_effort wayland wayland-protocols libxkbcommon gtk+3 lz4 pango fontconfig freetype vulkan-loader mesa libdrm libva gstreamer gst-plugins-base xdotool ;;
                *) : ;;
            esac
            ;;
    esac
}

version_ge(){ printf '%s\n%s\n' "$2" "$1" | sort -V -C; }

ensure_rust() {
    local min=1.88.0 cur=""
    if have rustc && have cargo; then
        cur="$(rustc --version | awk '{print $2}')"
        if version_ge "$cur" "$min"; then
            say "==> Rust OK: $cur"
            return
        fi
    fi

    say "==> Installing/updating Rust with rustup..."
    if ! have rustup; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
    rustup toolchain install stable
    rustup default stable
    export PATH="$HOME/.cargo/bin:$PATH"

    have rustc && have cargo || die "Rust installation failed."
    cur="$(rustc --version | awk '{print $2}')"
    version_ge "$cur" "$min" || die "Rust $min+ required; found $cur."
}

ensure_ryoku() {
    if have ryoku && have ryogami; then
        say "==> Ryoku detected."
        return
    fi

    case "$PM" in
        pacman|apt)
            say "==> Ryoku/Ryogami missing; running official Ryoku installer..."
            curl -fsSL "$RYOKU_INSTALL_URL" | bash -s -- --yes
            hash -r
            ;;
        *)
            die "Ryoku/Ryogami is missing. Ryoku's official shell installer currently targets pacman/apt hosts; install Ryoku first on this distro."
            ;;
    esac

    have ryoku && have ryogami || die "Ryoku install finished but ryoku/ryogami are still missing."
}

prepare_cef_dxc() {
    local mode="$1"
    [[ "$mode" == none ]] && return

    if [[ "$mode" == dxc ]]; then
        ./package/common/fetch-dependencies.sh dxc
        source ./package/common/versions.env
        mkdir -p .deps/dxc
        rm -rf .deps/dxc/*
        tar -xzf "${WE_LAYERD_DOWNLOAD_CACHE}/${DXC_ARCHIVE}" -C .deps/dxc
        export CMAKE_PREFIX_PATH="$PWD/.deps/dxc${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"
        export PATH="$PWD/.deps/dxc/bin:$PATH"
        return
    fi

    ./package/common/fetch-dependencies.sh all
    source ./package/common/versions.env
    mkdir -p .deps/cef .deps/dxc
    rm -rf .deps/cef/* .deps/dxc/*
    tar -xjf "${WE_LAYERD_DOWNLOAD_CACHE}/${CEF_ARCHIVE}" -C .deps/cef --strip-components=1
    tar -xzf "${WE_LAYERD_DOWNLOAD_CACHE}/${DXC_ARCHIVE}" -C .deps/dxc
    export CEF_ROOT="$PWD/.deps/cef"
    export CMAKE_PREFIX_PATH="$PWD/.deps/dxc${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"
    export PATH="$PWD/.deps/dxc/bin:$PATH"
}

build_we_layerd() {
    mkdir -p "$CACHE"

    if [[ -d "$WE_SRC/.git" ]]; then
        git -C "$WE_SRC" fetch --depth=1 origin main
        git -C "$WE_SRC" reset --hard origin/main
        git -C "$WE_SRC" submodule sync --recursive
        git -C "$WE_SRC" submodule update --init --recursive
    else
        rm -rf "$WE_SRC"
        git clone --depth=1 --recurse-submodules "$WE_REPO" "$WE_SRC"
    fi

    (
        cd "$WE_SRC"
        local mode=all
        case "$PM" in
            pacman) mode=none ;;
            dnf|yum) mode=dxc ;;
            apt) mode=all ;;
            *) mode=all ;;
        esac

        prepare_cef_dxc "$mode"
        git submodule update --init --recursive
        cargo build --locked --workspace --release
        cargo xtask install
    )

    export PATH="$HOME/.local/bin:$PATH"
    hash -r
}

ensure_we_layerd() {
    if have we-layerd; then
        say "==> we-layerd detected: $(command -v we-layerd)"
        return
    fi

    if [[ "$PM" == nix ]]; then
        say "==> Installing we-layerd via upstream Nix flake..."
        nix --extra-experimental-features 'nix-command flakes' profile install github:Aromatic05/we-layerd
        export PATH="$HOME/.nix-profile/bin:$PATH"
        hash -r
        have we-layerd || die "Nix install completed but we-layerd is missing."
        return
    fi

    install_we_deps
    ensure_rust
    say "==> Building we-layerd from upstream..."
    build_we_layerd
    have we-layerd || die "we-layerd build completed but executable is missing."
}

check_environment() {
    have systemctl || die "Ryoku-WE requires systemd user services."
    [[ -n "${WAYLAND_DISPLAY:-}" ]] || warn "WAYLAND_DISPLAY is not set."

    local p
    for p in \
        "$HOME/.local/share/Steam/steamapps/workshop/content/431960" \
        "$HOME/.steam/steam/steamapps/workshop/content/431960" \
        "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/workshop/content/431960"
    do
        if [[ -d "$p" ]]; then
            say "==> Wallpaper Engine Workshop detected: $p"
            return
        fi
    done
    warn "Wallpaper Engine Workshop content not found; local wallpapers still work."
}

install_ryoku_we() {
    say "==> Downloading Ryoku-WE..."
    curl -fsSL "${RAW}/Ryoku-WE" -o "$TMP"
    chmod +x "$TMP"
    say "==> Installing / repairing Ryoku-WE..."
    "$TMP" install
}

main() {
    detect_pm
    say "Ryoku-WE dependency bootstrap"
    say "============================"
    say "Package manager: $PM"
    say

    install_core
    ensure_ryoku
    ensure_we_layerd
    check_environment
    install_ryoku_we

    say
    say "Ryoku-WE installed successfully."
    say "Launch with: Ryoku-WE"
}

main "$@"
