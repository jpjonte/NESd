# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
