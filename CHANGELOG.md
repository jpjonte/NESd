# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- Added support for Namco 163 (Mapper 19; without additional audio for now)

### Changed

- Upgraded dependencies

## [0.10.0] - 2025-03-27

### Added

- Added support for PAL ROMs
- Added region auto-detection
- Added a flatpak build for linux
- Created a flatpak repo: https://jpjonte.github.io/flatpak/jpj.flatpakrepo

### Changed

- Improved performance by completely changing the implementation of cycle accuracy

### Fixed

- Android: Fixed an issue where the file picker would always crash with an error

## [0.9.0] - 2025-03-17

### Added

- MMC1: Improved accuracy by ignoring writes in consecutive cycles
- Show interrupt status in debugger
- Added frame count in the debug overlay
- Unofficial operations are now highlighted in red
- When an error occurs during emulation, an error toast message is shown
- Added a button to remove a ROM from the recent ROM list
- Added a button to delete a save state from the save states menu
- Added a button to create a new save state from the save states menu
- Gamepad inputs are now repeated when held down for easier menu navigation
- Added the option to remove a ROM from the recent ROM list if it could not be found while loading

### Changed

- Made the CPU implementation cycle accurate
  - Should improve compatibility in general
  - Battletoads is now playable
- Increased the limit of operations the disassembler will disassemble in one go from 100 to 200
- Improved usability of breakpoint dialogs
- Improved performance of the PPU code
- Improved test coverage and fixed some small bugs

### Fixed

- Fixed CNROM ROMs not starting up
- Fixed an issue where the disassembler would disassemble non-code data when encountering a BRK instruction
- Fixed an issue where multiple breakpoints could be added for the same address

## [0.8.0] - 2025-02-18

### Added

- Added support for MMC5 (mapper 5; without additional audio for now)

### Changed

- Upgraded to Flutter 3.29 and Dart 3.7
- Upgraded dependencies

### Removed

- Removed legacy save state serialization

### Fixed

- Fixed broken layout in the file picker
- Fixed constant reloading in the recent ROM list
- Fixed sprites leaking from the bottom of the screen into the first scanline
- Fixed missing garbage nametable fetches in the PPU
- Fixed inaccuracies in sprite rendering
- Fixed IRQs being acknowledged too early
- Fixed tile viewer affecting code execution

## [0.7.0] - 2024-11-01

### Added

- Added an editor for the touch controls
  - Controls can be added, moved, resized, and removed
  - Controls can be assigned any action
- Added a file picker for ZIPs that contain multiple ROMs

## [0.6.0] - 2024-09-08

### Added

- The stack can now be viewed in the debugger by hovering over the stack pointer
- Added support for the GxROM mapper
- Added thumbnails to the list of recent ROMs
- Added page navigation to the list of recent ROMs
- Added an overview page for the save states of a ROM (can be accessed from the pause menu or by long pressing the preview in the recent ROMs list)

### Changed

- Replaced the save state file format with a more robust, future-proof format
- Save states in the old format can be loaded for the next two releases

## [0.5.0] - 2024-08-26

### Added

- Added a setting to toggle the debugger
- Added support for the MMC2 mapper
- Added support for the greyscale and color emphasis bits in the PPU
- Added a button to reset control bindings to default
- Added support for the Namco108 mapper
- Added an option to automatically load the latest save state when a ROM is loaded

### Changed

- Cleaned up code for all mappers
- Upgraded all dependencies
- NESd now remembers breakpoints set for each ROM
- Breakpoints can now be disabled and enabled by long-pressing the line in the disassembly or ticking the checkbox in the breakpoint list
- Breakpoints can be set to be disabled or removed after being hit

### Removed

- Removed event time and events per second from the debug overlay

## [0.4.0] - 2024-08-18

### Added

- A hover overlay to the tile debug view
  - shows various parameters of the highlighted tile
  - can be locked and unlocked by clicking on the tile
- A basic debugger
  - bytecode and disassembly
  - current register values
  - step into, step over, step out, run to address
  - breakpoints
- An execution log
  - Records instructions as they are executed
  - Can be saved to a file

### Changed

- Games are now stopped completely if emulation crashes
- Improved performance of the CPU and the tile debug view

### Fixed

- Fixed an issue where the last opened directory was not saved
- Fixed file picker not correctly detecting directories on Android
- Fixed a bug in memory reads performed by the CPU
- Fixed graphical glitches on level start in Super Mario Bros. 3
- Fixed not all parts of nightly releases being updated

## [0.3.0] - 2024-07-28

### Added

- Android support
- Performance improvements
- Support for small and narrow screens
- Touch screen controls
- Debug overlay

### Fixed

- Autosave now only occurs when autosave is enabled and the game is running

## [0.2.0] - 2024-07-23

### Added

- This changelog!
- Support for ROMs loaded from a zip file
- Actions to pause the game and open the menu
- Support for multiple bindings per action
- Made menus navigable by gamepad
- Added a menu screen before the settings screen when in game
- Linux support
- Windows support
- Added a list of recently played ROMs
- Added toast messages for information and errors
- Added an about dialog
- Implemented a fast-forward action
- Added a menu button to the main screen when in game
- Automated builds and releases

### Fixed

- Bomberman title screen now works and the game is playable
- Fixed an issue where keyboard inputs where ignored until the arrow keys were pressed
- Fixed a crash that occurred if the last opened directory was no longer present

## [0.1.0] - 2024-06-28

### Added

- Gamepad support
- Customizable gamepad bindings
- "Open ROM" and Settings buttons on the main screen

## [0.0.1] - 2024-06-23

### Added

- CPU emulation
- PPU emulation
- APU emulation
- Customizable keyboard bindings
- SRAM saves
- Save states
- Autosave of SRAM
- Support for NROM (Mapper 0)
- Support for MMC1 (Mapper 1)
- Support for UNROM (Mapper 2)
- Support for CNROM (Mapper 3)
- Support for MMC3 (Mapper 4)
- Support for AxROM (Mapper 7)
- Support for BR909x (Mapper 71)
- Debug view for tiles and scrolling
- Detailed information about the loaded ROM
