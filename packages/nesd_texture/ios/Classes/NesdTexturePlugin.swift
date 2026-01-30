import Flutter
import UIKit

public class NesdTexturePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "nesd_texture", binaryMessenger: registrar.messenger())
    let instance = NesdTexturePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "createTexture", "updateTexture", "disposeTexture":
      result(FlutterError(code: "unimplemented",
                          message: "nesd_texture: \(call.method) is not implemented on iOS yet.",
                          details: nil))
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
