Pod::Spec.new do |s|
  s.name             = 'nesd_audio'
  s.version          = '0.1.0'
  s.summary          = "NESd's push-model PCM audio output plugin"
  s.description      = <<-DESC
  Native audio output for the NESd emulator: SPSC ring, underrun
  recovery, and device restart handling over miniaudio.
                       DESC
  s.homepage         = 'https://github.com/jpjonte/NESd'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'jpjonte' => 'john@make-better.de' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
