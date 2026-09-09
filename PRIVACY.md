# NESd Privacy Policy

Last updated: 2026-09-08

NESd is a Nintendo Entertainment System emulator. It has no backend
service and no account system.

## What the NESd app collects

Nothing. The NESd app does not collect, transmit, or share any personal
data. There are no analytics, no crash reporting, no advertising, and no
tracking of any kind. This applies to every platform, including the web
version and self-hosted copies.

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

## The website (nesd.jpj.dev)

The website counts page views so I can see how many people visit it and
how many open the in-browser version. The counter is
[GoatCounter](https://www.goatcounter.com), running on my own server. No
third party receives anything.

For each page view it records the time, the page address, and the
address of the site you came from, if your browser sends one. That is
all. It does not record your IP address, browser, operating system,
screen size, language, or location. It sets no cookies and does not
recognise you across visits or pages. Each page is counted once per
browser tab, however often you reload; the flag for that lives in your
browser only.

Opening the in-browser version at /play counts as one page view, the
same as any other page. Beyond that, the emulator itself sends nothing:
which games you play, for how long, and everything else stays in your
browser, as described above. Self-hosted copies of the web version
contain no counter at all.

If you block scripts, nothing is counted.

## Contact

Questions: nesd@jpj.dev
Source code: https://github.com/jpjonte/NESd
