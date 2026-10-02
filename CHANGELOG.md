# Changelog

## 2.4.1 - 2026-10-02

- Fixed Wallpaper Engine `video` projects not appearing in stable Ryogami.
- Stable Ryogami uses `paths.videoWallpaper` (normally `~/videowalls`) for video discovery, separate from `paths.wallpaper`.
- Workshop scene/still cards remain in `~/Pictures/Wallpapers/Wallpaper Engine`.
- Workshop videos are now indexed in `<paths.videoWallpaper>/Wallpaper Engine`.
- Added copy-on-write reflink fallback when a video cannot be hardlinked across filesystems.
- Stable index routing now resolves Workshop IDs from both generated index roots.

## 2.4.0 — Stable Ryogami compatibility

- Added a stable-compatible Wallpaper Engine picker index at `~/Pictures/Wallpapers/Wallpaper Engine`.
- Indexes Steam Workshop subscriptions from app ID `431960` without requiring Ryogami's online Workshop browser.
- Uses hardlinks for local media so stable Ryogami sees normal files instead of symlinks.
- Generates static picker cards for Wallpaper Engine `scene` projects and routes the real Workshop project to `we-layerd` when selected.
- Added `Ryoku-WE index` and a TUI action to rebuild the Workshop index manually.
- Added a systemd path watcher that refreshes the index when Steam Workshop subscriptions change.
- Preserves native Ryoku rendering for still images, GIFs, local videos, and Wallpaper Engine video projects.
- Keeps Wallpaper Engine scene audio integrated with the global Ryoku-WE mute state.
- Keeps the GIF `AnimatedImage` patch self-healing across Ryoku shell materialization/updates.

## 2.3.0

- Added unified TUI/CLI management.
- Added automatic scene routing through `we-layerd`.
- Added global wallpaper mute/unmute controls.
- Added persistent user services and status reporting.
