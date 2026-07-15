#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint audio_stream.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'mp_audio_stream'
  s.version          = '0.0.3'
  s.summary          = 'A simple multi-platform audio stream player for raw audio data streams'
  s.description      = <<-DESC
  A Flutter plug-in for multi platform simple audio stream playback with real-time generated audio data streams
                       DESC
  s.homepage         = 'https://github.com/reki2000/mp-audio-stream'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'reki2000' => '2533597+reki2000@users.noreply.github.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
