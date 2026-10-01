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
