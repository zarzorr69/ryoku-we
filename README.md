# Ryoku-WE

**Ryoku-WE** extends the normal Ryoku wallpaper workflow so still images, GIFs, videos, and Wallpaper Engine Workshop scenes can all be selected through Ryoku without forcing every wallpaper type through the same renderer.

> Community project. Ryoku-WE is not an official Ryoku component.

## What it supports

| Wallpaper type | Renderer |
| --- | --- |
| JPG / PNG / WebP / still images | Native Ryoku |
| Local GIF | Native Ryoku + `AnimatedImage` patch |
| Local video | Native Ryoku |
| Wallpaper Engine Workshop video | Native Ryoku |
| Wallpaper Engine Workshop scene | `we-layerd` |

Ryoku-WE also includes:

- A TUI for setup, repair, status, routing, and audio control
- Global wallpaper **mute / unmute**
- Automatic Wallpaper Engine `project.json` type detection
- Automatic renderer switching
- A persistent `we-layerd` user service
- A Wallpaper Engine selection watcher
- A self-healing GIF patch watcher
- Timestamped backups before install/repair
- Cleanup of the old synthetic Wallpaper Engine preview-folder workaround

## Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/zarzorr69/ryoku-we/main/install.sh | bash
```

The tiny `install.sh` loader downloads `bootstrap.sh`, verifies it with `bash -n`, and only then executes it.

The dependency bootstrap detects many package managers, including:

```text
pacman
apt / apt-get
dnf / dnf5
yum
zypper
xbps
apk
emerge
eopkg
swupd
urpmi
slackpkg
nix
guix
brew
pkg
opkg
```

On package-manager families without a known native `we-layerd` recipe, dependency installation is best-effort and the upstream source build is attempted. Ryoku itself must already be available on distributions where its own installer is not supported.

## Safer manual verification

If you want to inspect and syntax-check the installer before running it:

```bash
curl -fL --retry 3 \
  https://raw.githubusercontent.com/zarzorr69/ryoku-we/main/install.sh \
  -o /tmp/ryoku-we-install.sh

bash -n /tmp/ryoku-we-install.sh
bash /tmp/ryoku-we-install.sh
```

You can also verify the dependency bootstrap directly:

```bash
curl -fL --retry 3 \
  https://raw.githubusercontent.com/zarzorr69/ryoku-we/main/bootstrap.sh \
  -o /tmp/ryoku-we-bootstrap.sh

bash -n /tmp/ryoku-we-bootstrap.sh
```

## Repository layout

```text
ryoku-we/
├── README.md
├── install.sh
├── bootstrap.sh
└── Ryoku-WE
```

Keep the executable files executable:

```bash
chmod +x install.sh bootstrap.sh Ryoku-WE
```

## What the installer does

The bootstrap:

1. Detects the package manager.
2. Installs/checks core build dependencies.
3. Checks for Ryoku and Ryogami.
4. Checks for `we-layerd`.
5. Builds/installs `we-layerd` when needed.
6. Checks Wayland and Wallpaper Engine Workshop paths.
7. Downloads the current `Ryoku-WE`.
8. Runs `Ryoku-WE install`.

If `we-layerd` is already installed, it is reused instead of rebuilt.

## Launch the TUI

```bash
Ryoku-WE
```

or:

```bash
ryoku-we
```

The TUI displays the current wallpaper, route, Workshop metadata, audio state, and service status.

### TUI shortcuts

| Key | Action |
| --- | --- |
| `↑` / `↓` or `j` / `k` | Navigate |
| `Enter` | Select |
| `m` | Mute / unmute wallpaper audio |
| `s` | Sync current wallpaper / renderer |
| `r` | Install / repair |
| `q` | Quit |

## CLI commands

```bash
Ryoku-WE install
Ryoku-WE repair
Ryoku-WE status
Ryoku-WE sync
Ryoku-WE gif-patch
Ryoku-WE mute
Ryoku-WE unmute
Ryoku-WE toggle-mute
Ryoku-WE restart-we
Ryoku-WE picker
Ryoku-WE logo
Ryoku-WE uninstall
```

## Audio

Mute all wallpaper audio:

```bash
Ryoku-WE mute
```

Unmute:

```bash
Ryoku-WE unmute
```

Toggle:

```bash
Ryoku-WE toggle-mute
```

Ryoku-WE updates both the Ryoku wallpaper mute state and the `we-layerd` renderer configuration.

## How Wallpaper Engine routing works

Ryoku-WE watches:

```text
~/.local/state/ryoku-wallpaper
```

For a Wallpaper Engine Workshop item it reads:

```text
project.json
```

A Workshop `video` stays on the native Ryoku renderer.

A Workshop `scene` is routed to `we-layerd`:

1. The selected Workshop directory is written to `we-layerd`.
2. `we-layerd.service` is started/restarted.
3. Ryoku-WE confirms the replacement renderer is alive.
4. It stops only the native `skwd-wall-vk --scene` process for that exact scene.
5. Ryoku continues to own the picker, wallpaper state, shell, and all non-scene wallpapers.

Selecting a normal wallpaper or Workshop video stops `we-layerd` and returns rendering to Ryoku.

## GIF support

Ryoku-WE patches the Ryoku wallpaper `Backdrop.qml` buffers from `Image` to `AnimatedImage` and keeps their `ShaderEffectSource` live only for GIF sources.

The active/source files are:

```text
~/.config/quickshell/shell/modules/wallpaper/Backdrop.qml
~/.local/share/ryoku/rashin/source/quickshell/shell/modules/wallpaper/Backdrop.qml
```

A user systemd path unit reapplies the patch if Ryoku replaces `Backdrop.qml`.

After a Ryoku update:

```bash
Ryoku-WE repair
```

## Steam / Wallpaper Engine detection

Ryoku-WE checks the common Steam roots:

```text
~/.local/share/Steam
~/.steam/steam
~/.var/app/com.valvesoftware.Steam/.local/share/Steam
```

Wallpaper Engine Workshop content is expected under:

```text
steamapps/workshop/content/431960
```

Wallpaper Engine assets are expected under:

```text
steamapps/common/wallpaper_engine/assets
```

## systemd user units

Ryoku-WE creates/manages:

```text
we-layerd.service
ryoku-we-sync.service
ryoku-we-sync.path
ryoku-gif-wallpaper-patch.service
ryoku-gif-wallpaper-patch.path
```

Useful checks:

```bash
systemctl --user status we-layerd.service
systemctl --user status ryoku-we-sync.path
systemctl --user status ryoku-gif-wallpaper-patch.path
```

## Status

```bash
Ryoku-WE status
```

Shows:

- Current wallpaper
- Workshop ID/type/title
- Native Ryoku vs `we-layerd` route
- Wallpaper audio state
- Renderer processes
- Watcher/service state

## Backups

Before install/repair, relevant files are backed up under:

```text
~/.local/share/ryoku-we/backups/
```

## Uninstall

```bash
Ryoku-WE uninstall
```

This removes/disables the automation units and stops `we-layerd`.

Backups and the current GIF QML modification are intentionally retained instead of destructively rewriting the shell configuration.
