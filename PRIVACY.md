# NESd Privacy Policy

Last updated: 2026-08-24

NESd is a Nintendo Entertainment System emulator. It has no backend
service and no account system.

## What NESd collects

Nothing. NESd does not collect, transmit, or share any personal data.
There are no analytics, no crash reporting, no advertising, and no
tracking of any kind.

## What NESd stores on your device

Everything below stays on your device, is never transmitted, and is
everything NESd itself writes:

- References to recently opened ROMs (file paths and hashes, not the
  ROM data)
- Battery-backed save data (SRAM) and save states
- Per-game thumbnail images generated from gameplay
- Your settings, including control bindings and touch-control layouts

On Android, uninstalling NESd removes all of the above, because it is
stored in the app's private data directory. Your ROM files are
unaffected. They live wherever you put them, independent of the app,
so uninstalling never deletes them.

On macOS, Windows and Linux, the data above is stored in the OS's
standard per-app data directory (for example
`~/Library/Application Support/...`, `%APPDATA%`, or
`~/.local/share/...`). Removing the app, i.e. dragging it to the Trash, or
running a typical uninstaller, does not reliably delete this
directory.

On the web version, imported ROM files, SRAM saves, save states, and
thumbnails are stored in your browser's site storage (IndexedDB) for the
site you're playing on (nesd.jpj.dev, or a self-hosted instance), on
your own device. They are never uploaded anywhere. Clearing your
browser's site data for that site removes all of it.

## Network access

The web version is delivered over the network.
Beyond that, NESd does not require network access, and your
ROMs, saves, and other game data never leave your browser.

## Contact

Questions: nesd@jpj.dev
Source code: https://github.com/jpjonte/NESd
