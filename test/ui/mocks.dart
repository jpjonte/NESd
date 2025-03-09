import 'package:mocktail/mocktail.dart';
import 'package:mp_audio_stream/mp_audio_stream.dart';
import 'package:nesd/ui/file_picker/file_system/file_system.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAudioStream extends Mock implements AudioStream {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockFileSystem extends Mock implements FileSystem {}
