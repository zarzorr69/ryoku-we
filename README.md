# Ryoku-WE

Ryoku-WE extends the normal Ryoku wallpaper workflow with Wallpaper Engine Workshop support while keeping Ryoku's own picker and native renderers wherever possible.

It is designed around a simple split:

| Wallpaper type | Renderer |
| --- | --- |
| JPG / PNG / WebP | Native Ryoku |
| Local GIF | Native Ryoku + `AnimatedImage` patch |
| Local video | Native Ryoku |
| Wallpaper Engine `video` project | Native Ryoku |
| Wallpaper Engine `scene` project | `we-layerd` |

Ryoku-WE does **not** replace Super+W with a separate wallpaper browser. It extends the existing Ryoku workflow.

## Why this exists

Newer unstable Ryogami builds include deeper native Wallpaper Engine/Workshop integration, but stable Ryogami releases may not expose the raw Steam Workshop tree in the picker.

Ryoku-WE adds a stable-compatible local index under:

```text
~/Pictures/Wallpapers/Wallpaper Engine
```

Steam remains the source of truth. Subscribe/unsubscribe through Steam Workshop normally; Ryoku-WE watches the Workshop directory and refreshes the local picker index.

For scene projects the picker shows a static preview, but selecting that preview is mapped back to the real Workshop ID and the actual project directory is rendered through `we-layerd`.

## Features

- Works with the normal Ryoku Super+W wallpaper picker.
- Stable-compatible Wallpaper Engine subscription index.
- Automatic Workshop project type detection from `project.json`.
- Native handling for Wallpaper Engine video projects.
- `we-layerd` routing for Wallpaper Engine scene projects.
- Automatic index refresh when Steam subscriptions change.
- Manual `Ryoku-WE index` refresh command.
- Local GIF support through a small Quickshell `AnimatedImage` patch.
- Self-healing GIF patch watcher.
- Global wallpaper mute / unmute.
- TUI for status, repair, routing, index refresh, and audio controls.
- Timestamped backups before install/repair.

## Requirements

- Linux + Wayland
- Ryoku / Ryogami already installed, or a distro supported by Ryoku's official installer
- systemd user services
- Python 3
- ffmpeg
- Steam + Wallpaper Engine for Workshop support
- `we-layerd` for Wallpaper Engine scene projects

The bootstrap script can install/check most dependencies and build `we-layerd` when necessary.

## Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/zarzorr69/ryoku-we/main/install.sh | bash
```

`install.sh` downloads `bootstrap.sh`, syntax-checks it, then starts the dependency/bootstrap flow.

After installation:

```bash
Ryoku-WE
```

or:

```bash
ryoku-we
```

## Manual install

Clone the repository and run:

```bash
git clone https://github.com/zarzorr69/ryoku-we.git
cd ryoku-we
chmod +x install.sh bootstrap.sh Ryoku-WE
./bootstrap.sh
```

If all dependencies are already present:

```bash
./Ryoku-WE install
```

## Steam / Wallpaper Engine paths

Ryoku-WE checks common Steam roots including:

```text
~/.local/share/Steam
~/.steam/steam
~/.var/app/com.valvesoftware.Steam/.local/share/Steam
```

Wallpaper Engine Workshop subscriptions are expected under:

```text
steamapps/workshop/content/431960
```

Wallpaper Engine assets are expected under:

```text
steamapps/common/wallpaper_engine/assets
```

## Stable picker index

Stable Ryogami may ignore symlinks and does not scan Steam's nested Workshop structure directly. It also uses separate roots for still wallpapers and video wallpapers. Ryoku-WE therefore creates two matching picker indexes:

```text
~/Pictures/Wallpapers/Wallpaper Engine        # scene/still cards
<paths.videoWallpaper>/Wallpaper Engine      # video projects (normally ~/videowalls/Wallpaper Engine)
```

Each filename begins with the Workshop ID, for example:

```text
~/Pictures/Wallpapers/Wallpaper Engine/3483400361 - Aeolian 4K by Wlop [scene].jpg
~/videowalls/Wallpaper Engine/3300777757 - WLOP Sky [video].mp4
```

Ryoku-WE reads `paths.videoWallpaper` from `~/.config/ryoku/ryogami.json`, so custom stable video-library paths are respected automatically.

The ID lets Ryoku-WE resolve the selected card back to:

```text
~/.local/share/Steam/steamapps/workshop/content/431960/<ID>
```

### Scene projects

Scene projects use a static preview card in the picker. When selected:

1. Ryoku writes the selected index path to its wallpaper state.
2. Ryoku-WE extracts the Workshop ID from the generated filename.
3. The real Workshop project directory is set as `we-layerd`'s source.
4. `we-layerd.service` is restarted.
5. The native scene process for that exact project is stopped if necessary.
6. The temporary/static picker preview is hidden so the real scene is visible below the shell.

### Video projects

Wallpaper Engine projects whose `project.json` type is `video` are indexed under Ryogami's dedicated `paths.videoWallpaper` root instead of the still-image root. This is required by the stable picker. The video remains on Ryoku's native video renderer.

### Filesystem note

Full video entries use hardlinks when possible so the picker sees them as real files without duplicating video data. If Steam and the video wallpaper directory are on different filesystems, Ryoku-WE tries a copy-on-write reflink (`cp --reflink=always`) and otherwise skips the item instead of silently making a full duplicate. Scene preview images are small and may fall back to a normal copy.

## CLI commands

```bash
Ryoku-WE install
Ryoku-WE repair
Ryoku-WE status
Ryoku-WE sync
Ryoku-WE index
Ryoku-WE gif-patch
Ryoku-WE mute
Ryoku-WE unmute
Ryoku-WE toggle-mute
Ryoku-WE restart-we
Ryoku-WE picker
Ryoku-WE logo
Ryoku-WE uninstall
```

### `index`

Rebuild the stable Wallpaper Engine picker index:

```bash
Ryoku-WE index
```

Use this after subscribing/unsubscribing manually if you do not want to wait for the watcher.

### `sync`

Route the currently selected wallpaper to the correct renderer:

```bash
Ryoku-WE sync
```

### `status`

Show the current wallpaper, Workshop ID/type/title, active route, audio state, services, and renderer processes:

```bash
Ryoku-WE status
```

## TUI

Run without arguments:

```bash
Ryoku-WE
```

The TUI includes actions for:

- opening the Ryoku picker
- muting/unmuting wallpaper audio
- syncing the current renderer
- refreshing the Wallpaper Engine index
- reapplying GIF support
- restarting the Wallpaper Engine renderer
- install/repair
- detailed status
- uninstalling automation

## GIF support

Ryoku-WE patches Ryoku's wallpaper `Backdrop.qml` so GIF sources use `AnimatedImage`, while normal still images continue using the same wallpaper surface.

The active/source locations are normally:

```text
~/.config/quickshell/shell/modules/wallpaper/Backdrop.qml
~/.local/share/ryoku/rashin/source/quickshell/shell/modules/wallpaper/Backdrop.qml
```

A systemd path unit reapplies the GIF patch if Ryoku replaces the active file.

After a Ryoku update, run:

```bash
Ryoku-WE repair
```

## systemd user units

Ryoku-WE manages:

```text
we-layerd.service
ryoku-we-sync.service
ryoku-we-sync.path
ryoku-we-index.service
ryoku-we-index.path
ryoku-gif-wallpaper-patch.service
ryoku-gif-wallpaper-patch.path
```

Useful checks:

```bash
systemctl --user status we-layerd.service
systemctl --user status ryoku-we-sync.path
systemctl --user status ryoku-we-index.path
systemctl --user status ryoku-gif-wallpaper-patch.path
```

## Repair

Install/repair is intended to be repeatable:

```bash
Ryoku-WE repair
```

It backs up relevant configuration, reinstalls the local executable, checks the Ryoku/WE configuration, reapplies required QML support, rebuilds the Workshop index, rewrites the user units, and synchronizes the current wallpaper route.

## Uninstall automation

```bash
Ryoku-WE uninstall
```

This disables/removes Ryoku-WE's user units and stops `we-layerd`.

The generated picker index, GIF QML modifications, and backups are intentionally left in place rather than deleted automatically. This avoids destructive cleanup of user-visible wallpaper state.

## Repository layout

```text
ryoku-we/
├── .gitignore
├── CHANGELOG.md
├── README.md
├── Ryoku-WE
├── bootstrap.sh
└── install.sh
```

Make the executable files executable before committing:

```bash
chmod +x Ryoku-WE bootstrap.sh install.sh
```

## Project status

Ryoku-WE is a community integration and is not an official Ryoku or Wallpaper Engine component.

It has been developed around the Ryoku/Ryogami wallpaper stack on Wayland/Hyprland, including the stable picker compatibility path described above.
