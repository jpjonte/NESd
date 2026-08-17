#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint nesd_texture.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'nesd_texture'
  s.version          = '0.0.1'
  s.summary          = "NESd's GPU frame presentation plugin"
  s.description      = <<-DESC
  Registers a platform texture that the emulator renders PPU frames into,
  so frames reach the GPU without a per-frame bitmap copy.
                       DESC
  s.homepage         = 'https://github.com/jpjonte/NESd'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'jpjonte' => 'nesd@jpj.dev' }

  s.source           = { :path => '.' }
  s.source_files = 'nesd_texture/Sources/nesd_texture/**/*.swift'
  s.resource_bundles = {'nesd_texture_privacy' => ['nesd_texture/Sources/nesd_texture/Resources/PrivacyInfo.xcprivacy']}

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.15'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
