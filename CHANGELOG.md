# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- Added a setting to toggle the debugger
- Added support for the MMC2 mapper
- Added support for the greyscale and color emphasis bits in the PPU
- Added a button to reset control bindings to default
- Added support for the Namco108 mapper

### Changed

- Cleaned up code for all mappers
- Upgraded all dependencies
- NESd now remembers breakpoints set for each ROM

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
