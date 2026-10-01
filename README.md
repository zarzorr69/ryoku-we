# Ryoku-WE

```text
000010000010101111000011010010100100110010001101010100111010
100011101111011011001100000011000010101001101111100001110001
010100111100100111001110000010001000101001001010110111010000
001001000011010001110011101110111000111000001110110100101100
110100011010111111111001100011011111101000011110010010000111
110001111110001111101111010001010010001010000011000000010110
000110111000011011100101011000001111100110001011100110010100
100111000111000011000101100010011111101010110110001101010100
001001001110101001001001100111111110101100011100110101000110
010001111110011000101111011010110011100000001000101110001100
010011010000010001001111100011011001100101011010011010000001
011100101101000110110001010100100101011001101100101111011100
101011010111001000100010001101100000001101100001101100010111
010111110001000010001110010001000101010011101111000010100001
000000000110001100011010001101010011110101110110000110110101
011000110100010100010100100111100011001100101101110111101010
101111101000010001101000001001001001011101001010000001100010
100110010010001111101100000000001011110001111101001010110100
100010101110111010101100110000111011111111100111101101001011
001001010110010001111100100001000110011111010010100110110011
111010010000001101100110011010100100010001110000100000001100
001001100101111111110011010100111110100000111101001011110111
101111001011100100001101000111100010100101110001100101010000
001100110100000100011100101110010001101000011011111000000101
011000010011111001010010111011011001111011111011010111110000
001110001110010100001110001011110010111101001001101000100001
010010100011110011100001101010111001011101110010000100101000
```

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
