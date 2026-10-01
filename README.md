# Ryoku-WE

**Ryoku-WE** adds a unified wallpaper layer to Ryoku so the normal Ryoku wallpaper picker can handle still images, GIFs, videos, and Wallpaper Engine Workshop scenes without forcing everything through one renderer.

It keeps Ryoku's native rendering wherever it already works well, patches local GIF support into the Quickshell wallpaper surface, and automatically routes Wallpaper Engine `scene` projects through `we-layerd`.

> Community project. Ryoku-WE is not an official Ryoku component.

## What it supports

| Wallpaper type | Renderer |
| --- | --- |
| JPG / PNG / WebP / still images | Native Ryoku |
| Local GIF | Native Ryoku + `AnimatedImage` patch |
| Local video | Native Ryoku |
| Wallpaper Engine Workshop video | Native Ryoku |
| Wallpaper Engine Workshop scene | `we-layerd` |

Ryoku-WE also provides:

- A terminal UI for setup, status, repair, renderer sync, and audio control
- Global wallpaper **mute / unmute**
- Automatic Wallpaper Engine project-type detection from `project.json`
- Automatic renderer switching when the wallpaper changes
- A systemd user service for `we-layerd`
- A systemd path watcher for Workshop scene routing
- A self-healing GIF patch watcher
- Removal of the old synthetic Wallpaper Engine preview-folder workaround
- Timestamped configuration backups before installation/repair

## Requirements

Ryoku-WE expects:

- Ryoku with `ryoku` and `ryogami` available in `PATH`
- Python 3
- systemd user services
- `we-layerd` installed and available in `PATH` or at `~/.local/bin/we-layerd`
- Steam + Wallpaper Engine for Workshop scene support
- A normal Ryoku/Quickshell wallpaper configuration

Ryoku-WE was built around the Ryoku 0.81-era wallpaper stack. If a future Ryoku update changes `Backdrop.qml`, run the repair command and check the output.

## Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/zarzorr69/ryoku-we/main/install.sh | bash
```

The installer downloads the current `Ryoku-WE` executable, installs it to:

```text
~/.local/bin/Ryoku-WE
```

and also creates:

```text
~/.local/bin/ryoku-we
```

as a lowercase convenience alias.

## Manual install

```bash
curl -fsSL https://raw.githubusercontent.com/zarzorr69/ryoku-we/main/Ryoku-WE -o /tmp/Ryoku-WE
chmod +x /tmp/Ryoku-WE
/tmp/Ryoku-WE install
rm -f /tmp/Ryoku-WE
```

## Launch the TUI

```bash
Ryoku-WE
```

or:

```bash
ryoku-we
```

The TUI shows the current wallpaper, routing backend, Workshop project information, audio state, and service/watch status.

### TUI shortcuts

| Key | Action |
| --- | --- |
| `↑` / `↓` | Navigate |
| `Enter` | Select |
| `m` | Mute / unmute wallpaper audio |
| `s` | Sync the current wallpaper renderer |
| `r` | Install / repair support |
| `q` | Quit |

## CLI commands

The TUI is optional. Everything important is also available from the command line:

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
Ryoku-WE uninstall
```

### Mute / unmute

Mute wallpaper audio:

```bash
Ryoku-WE mute
```

Unmute wallpaper audio:

```bash
Ryoku-WE unmute
```

Toggle the current state:

```bash
Ryoku-WE toggle-mute
```

The toggle updates both the Ryoku wallpaper audio setting and the `we-layerd` renderer configuration so native Workshop videos and routed Wallpaper Engine scenes follow the same preference.

## How routing works

Ryoku-WE watches:

```text
~/.local/state/ryoku-wallpaper
```

When a wallpaper changes, it checks whether the selection is inside Wallpaper Engine's Workshop directory.

For Workshop projects it reads:

```text
project.json
```

If the project is a `video`, Ryoku remains in control.

If the project is a `scene`, Ryoku-WE:

1. Updates the `we-layerd` source to the selected Workshop project.
2. Starts or restarts `we-layerd.service`.
3. Confirms `we-layerd` is alive.
4. Stops only the native `skwd-wall-vk --scene` renderer for that exact project.
5. Leaves Ryoku's picker, shell, state management, and non-scene wallpaper rendering untouched.

Switching back to a normal wallpaper or Workshop video stops `we-layerd` and returns rendering to Ryoku.

## GIF support

Ryoku-WE patches the current Ryoku `Backdrop.qml` so the two wallpaper image buffers use `AnimatedImage` and keep their `ShaderEffectSource` live only for GIF sources.

The patch is applied to:

```text
~/.config/quickshell/shell/modules/wallpaper/Backdrop.qml
~/.local/share/ryoku/rashin/source/quickshell/shell/modules/wallpaper/Backdrop.qml
```

A systemd path unit watches the active `Backdrop.qml` and reapplies the patch if Ryoku replaces it.

After a Ryoku update, you can also force a repair manually:

```bash
Ryoku-WE repair
```

## Wallpaper Engine paths

Ryoku-WE automatically detects the usual Steam locations, including:

```text
~/.local/share/Steam
~/.steam/steam
~/.var/app/com.valvesoftware.Steam/.local/share/Steam
```

Wallpaper Engine Workshop content is expected under:

```text
steamapps/workshop/content/431960
```

and Wallpaper Engine assets under:

```text
steamapps/common/wallpaper_engine/assets
```

## systemd units

Ryoku-WE creates these user units:

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

This displays:

- Selected wallpaper
- Workshop ID
- Workshop project type/title
- Native Ryoku vs `we-layerd` routing
- Wallpaper mute state
- Renderer processes
- Relevant systemd service/watch state

## Repair after a Ryoku update

If Ryoku materializes or replaces its wallpaper QML:

```bash
Ryoku-WE repair
```

Repair is designed to be safe to run repeatedly. It rechecks the configuration, GIF patch, services, Workshop paths, and current route.

## Backups

Before install/repair, Ryoku-WE backs up relevant files under:

```text
~/.local/share/ryoku-we/backups/
```

It also moves obsolete synthetic Wallpaper Engine preview folders out of the normal Ryoku wallpaper directory rather than deleting them.

## Uninstall

```bash
Ryoku-WE uninstall
```

This disables/removes the Ryoku-WE automation units and stops `we-layerd`.

The current GIF QML changes and backups are intentionally retained instead of destructively rewriting your configuration.

## Repository layout

Recommended root layout:

```text
ryoku-we/
├── README.md
├── install.sh
└── Ryoku-WE
```

`Ryoku-WE` should remain executable:

```bash
chmod +x Ryoku-WE install.sh
```

## Notes

Ryoku-WE intentionally does **not** replace Ryoku's Super+W wallpaper UI. The goal is to extend the existing workflow rather than create a separate wallpaper browser.

For normal images and video, Ryoku stays native. `we-layerd` is only used where Wallpaper Engine scene compatibility needs it.
