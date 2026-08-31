import 'dart:typed_data';

import 'package:nesd/log/log_level.dart';
import 'package:nesd/nes/bus.dart';
import 'package:nesd/nes/cheat/cheat.dart';
import 'package:nesd/nes/database/database.dart';
import 'package:nesd/nes/debugger/breakpoint.dart';
import 'package:nesd/nes/fast_forward_speed.dart';
import 'package:nesd/nes/isolate/nes_bytes.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/nes/turbo_speed.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem_file.dart';

sealed class NesCommand {
  const NesCommand();
}

class LoadRomCommand extends NesCommand {
  const LoadRomCommand({
    required this.rom,
    required this.file,
    required this.databaseEntry,
    required this.region,
    required this.rewindEnabled,
    required this.cheats,
    required this.breakpoints,
    this.rewindCaptureInterval = 1,
    this.initialState,
    this.sram,
    this.suspended = false,
  });

  final NesBytes rom;
  final FilesystemFile file;
  final NesDatabaseEntry? databaseEntry;
  final Region? region;
  final bool rewindEnabled;
  final List<Cheat> cheats;
  final List<Breakpoint> breakpoints;
  final int rewindCaptureInterval;
  final NesBytes? initialState;
  final NesBytes? sram;
  final bool suspended;
}

class ResetCommand extends NesCommand {
  const ResetCommand();
}

class PauseCommand extends NesCommand {
  const PauseCommand();
}

class UnpauseCommand extends NesCommand {
  const UnpauseCommand();
}

class TogglePauseCommand extends NesCommand {
  const TogglePauseCommand();
}

class SuspendCommand extends NesCommand {
  const SuspendCommand();
}

class ResumeCommand extends NesCommand {
  const ResumeCommand();
}

class StopCommand extends NesCommand {
  const StopCommand();
}

class ShutdownCommand extends NesCommand {
  const ShutdownCommand();
}

class ButtonDownCommand extends NesCommand {
  const ButtonDownCommand({
    required this.controller,
    required this.button,
    this.turbo = false,
  });

  final int controller;
  final NesButton button;
  final bool turbo;
}

class ButtonUpCommand extends NesCommand {
  const ButtonUpCommand({
    required this.controller,
    required this.button,
    this.turbo = false,
  });

  final int controller;
  final NesButton button;
  final bool turbo;
}

class ButtonToggleCommand extends NesCommand {
  const ButtonToggleCommand({
    required this.controller,
    required this.button,
    this.turbo = false,
  });

  final int controller;
  final NesButton button;
  final bool turbo;
}

class ToggleFastForwardCommand extends NesCommand {
  const ToggleFastForwardCommand();
}

class ToggleRewindCommand extends NesCommand {
  const ToggleRewindCommand();
}

class SetRewindEnabledCommand extends NesCommand {
  const SetRewindEnabledCommand({required this.enabled});

  final bool enabled;
}

class SetFastForwardCommand extends NesCommand {
  const SetFastForwardCommand({required this.enabled});

  final bool enabled;
}

class SetRewindCommand extends NesCommand {
  const SetRewindCommand({required this.enabled});

  final bool enabled;
}

class SetRegionCommand extends NesCommand {
  const SetRegionCommand({required this.region});

  /// Null means: auto-detect from database entry / filename (worker-side).
  final Region? region;
}

class SetCheatsCommand extends NesCommand {
  const SetCheatsCommand({required this.cheats});

  final List<Cheat> cheats;
}

class SetVolumeCommand extends NesCommand {
  const SetVolumeCommand({required this.volume});

  final double volume;
}

class SetFastForwardSpeedCommand extends NesCommand {
  const SetFastForwardSpeedCommand({required this.speed});

  final FastForwardSpeed speed;
}

class SetTurboSpeedCommand extends NesCommand {
  const SetTurboSpeedCommand({required this.speed});

  final TurboSpeed speed;
}

class SetLowPassFilterCommand extends NesCommand {
  const SetLowPassFilterCommand({required this.enabled});

  final bool enabled;
}

class SetSwapDutyCyclesCommand extends NesCommand {
  const SetSwapDutyCyclesCommand({required this.enabled});

  final bool enabled;
}

class SetPaletteCommand extends NesCommand {
  const SetPaletteCommand({required this.palette});

  final Uint32List palette;
}

class StartPcmDumpCommand extends NesCommand {
  const StartPcmDumpCommand({required this.path});

  final String path;
}

class StopPcmDumpCommand extends NesCommand {
  const StopPcmDumpCommand();
}

class AddBreakpointCommand extends NesCommand {
  const AddBreakpointCommand({required this.breakpoint});

  final Breakpoint breakpoint;
}

class RemoveBreakpointCommand extends NesCommand {
  const RemoveBreakpointCommand({required this.address});

  final int address;
}

class SetBreakpointsCommand extends NesCommand {
  const SetBreakpointsCommand({required this.breakpoints});

  final List<Breakpoint> breakpoints;
}

class StepIntoCommand extends NesCommand {
  const StepIntoCommand();
}

class StepOverCommand extends NesCommand {
  const StepOverCommand();
}

class StepOutCommand extends NesCommand {
  const StepOutCommand();
}

class RunUntilFrameCommand extends NesCommand {
  const RunUntilFrameCommand();
}

class SetDebuggerActiveCommand extends NesCommand {
  const SetDebuggerActiveCommand({required this.active});

  final bool active;
}

class SetExecutionLogEnabledCommand extends NesCommand {
  const SetExecutionLogEnabledCommand({required this.enabled});

  final bool enabled;
}

class SetApuDebugEnabledCommand extends NesCommand {
  const SetApuDebugEnabledCommand({required this.enabled});

  final bool enabled;
}

class SaveStateRequest extends NesCommand {
  const SaveStateRequest({required this.requestId});

  final int requestId;
}

class LoadStateCommand extends NesCommand {
  const LoadStateCommand({required this.state});

  final NesBytes state;
}

class SaveSramRequest extends NesCommand {
  const SaveSramRequest({required this.requestId});

  final int requestId;
}

class LoadSramCommand extends NesCommand {
  const LoadSramCommand({required this.sram});

  final NesBytes sram;
}

class ThumbnailRequest extends NesCommand {
  const ThumbnailRequest({required this.requestId});

  final int requestId;
}

class TileDebugRequest extends NesCommand {
  const TileDebugRequest({required this.requestId});

  final int requestId;
}

class ReleaseFrameCommand extends NesCommand {
  const ReleaseFrameCommand({required this.frameHandle});

  /// The `FrameEvent.frameHandle` of the frame to return to the pool.
  final int frameHandle;
}

class SetZapperPositionCommand extends NesCommand {
  const SetZapperPositionCommand({required this.x, required this.y});

  final double? x;
  final double? y;
}

class ZapperPullCommand extends NesCommand {
  const ZapperPullCommand();
}

class ZapperReleaseCommand extends NesCommand {
  const ZapperReleaseCommand();
}

class SetLogLevelCommand extends NesCommand {
  const SetLogLevelCommand({required this.level});

  final LogLevel level;
}
