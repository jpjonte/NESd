import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  var engine: FlutterEngine?

  override func applicationShouldTerminateAfterLastWindowClosed(
    _ sender: NSApplication
  ) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(
    _ app: NSApplication
  ) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Without this, macOS merges the Dart-created tool windows into tabs
    // of one window when "Prefer tabs when opening documents" is Always.
    NSWindow.allowsAutomaticWindowTabbing = false

    let project = FlutterDartProject()
    project.dartEntrypointArguments = Array(CommandLine.arguments.dropFirst())

    let engine = FlutterEngine(name: "nesd", project: project)

    engine.run(withEntrypoint: nil)
    RegisterGeneratedPlugins(registry: engine)

    self.engine = engine
  }
}
