import Cocoa
import CoreVideo
import FlutterMacOS

private enum NesdTextureError: Error {
  case pixelBufferCreation
  case pixelBufferLock
  case invalidDimensions
}

private final class NesdPixelBufferTexture: NSObject, FlutterTexture {
  private let width: Int
  private let height: Int
  private var pixelBufferPool: CVPixelBufferPool?
  private var pixelBuffer: CVPixelBuffer?
  private let syncQueue = DispatchQueue(label: "dev.jpj.nesd_texture.texture", qos: .userInitiated)

  init(width: Int, height: Int) {
    self.width = width
    self.height = height
    super.init()
  }

  func update(width: Int, height: Int, pixels: Data) throws {
    guard width == self.width, height == self.height else {
      throw NesdTextureError.invalidDimensions
    }

    try syncQueue.sync {
      if pixelBufferPool == nil {
        try createPool()
      }

      guard let pool = pixelBufferPool else {
        throw NesdTextureError.pixelBufferCreation
      }

      var buffer: CVPixelBuffer?
      let status = CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer)

      guard status == kCVReturnSuccess, let buffer else {
        throw NesdTextureError.pixelBufferCreation
      }

      let lockStatus = CVPixelBufferLockBaseAddress(buffer, [])

      guard lockStatus == kCVReturnSuccess else {
        throw NesdTextureError.pixelBufferLock
      }

      defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

      guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else {
        throw NesdTextureError.pixelBufferLock
      }

      let destination = baseAddress.assumingMemoryBound(to: UInt8.self)

      pixels.withUnsafeBytes { srcRawBuffer in
        let source = srcRawBuffer.bindMemory(to: UInt8.self).baseAddress!
        let pixelCount = width * height

        var srcIndex = 0
        var dstIndex = 0

        for _ in 0..<pixelCount {
          let r = source[srcIndex + 0]
          let g = source[srcIndex + 1]
          let b = source[srcIndex + 2]
          let a = source[srcIndex + 3]

          destination[dstIndex + 0] = b
          destination[dstIndex + 1] = g
          destination[dstIndex + 2] = r
          destination[dstIndex + 3] = a

          srcIndex += 4
          dstIndex += 4
        }
      }

      pixelBuffer = buffer
    }
  }

  func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
    return syncQueue.sync {
      guard let buffer = pixelBuffer else {
        return nil
      }

      return Unmanaged.passRetained(buffer)
    }
  }

  func reset() {
    syncQueue.sync {
      pixelBuffer = nil
      pixelBufferPool = nil
    }
  }

  private func createPool() throws {
    let pixelFormat = kCVPixelFormatType_32BGRA

    let poolAttributes: [String: Any] = [
      kCVPixelBufferPoolMinimumBufferCountKey as String: 2
    ]

    let pixelBufferAttributes: [String: Any] = [
      kCVPixelBufferPixelFormatTypeKey as String: pixelFormat,
      kCVPixelBufferWidthKey as String: width,
      kCVPixelBufferHeightKey as String: height,
      kCVPixelBufferBytesPerRowAlignmentKey as String: width * 4,
      kCVPixelBufferIOSurfacePropertiesKey as String: [:]
    ]

    var pool: CVPixelBufferPool?
    let status = CVPixelBufferPoolCreate(nil,
                                           poolAttributes as CFDictionary,
                                           pixelBufferAttributes as CFDictionary,
                                           &pool)

    guard status == kCVReturnSuccess, let pool else {
      throw NesdTextureError.pixelBufferCreation
    }

    pixelBufferPool = pool
  }
}

public class NesdTexturePlugin: NSObject, FlutterPlugin {
  private let textures: FlutterTextureRegistry
  private var managedTextures: [Int64: NesdPixelBufferTexture] = [:]
  private let responseQueue = DispatchQueue(label: "dev.jpj.nesd_texture.plugin", qos: .userInitiated)

  init(registrar: FlutterPluginRegistrar) {
    self.textures = registrar.textures
    super.init()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "nesd_texture", binaryMessenger: registrar.messenger)
    let instance = NesdTexturePlugin(registrar: registrar)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "createTexture":
      handleCreate(call: call, result: result)

    case "updateTexture":
      handleUpdate(call: call, result: result)

    case "disposeTexture":
      handleDispose(call: call, result: result)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleCreate(call: FlutterMethodCall, result: FlutterResult) {
    guard
      let args = call.arguments as? [String: Any],
      let width = args["width"] as? Int,
      let height = args["height"] as? Int
    else {
      result(FlutterError(code: "invalid-argument",
                          message: "createTexture expects width and height",
                          details: nil))
      return
    }

    let texture = NesdPixelBufferTexture(width: width, height: height)
    let textureId = textures.register(texture)
    managedTextures[textureId] = texture
    result(textureId)
  }

  private func handleUpdate(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let args = call.arguments as? [String: Any],
      let textureId = args["textureId"] as? Int,
      let width = args["width"] as? Int,
      let height = args["height"] as? Int,
      let pixels = args["pixels"] as? FlutterStandardTypedData,
      let texture = managedTextures[Int64(textureId)]
    else {
      result(FlutterError(code: "invalid-argument",
                          message: "updateTexture expects textureId, width, height, pixels",
                          details: nil))
      return
    }

    responseQueue.async { [weak self] in
      do {
        try texture.update(width: width, height: height, pixels: pixels.data)
        DispatchQueue.main.async {
          self?.textures.textureFrameAvailable(Int64(textureId))
          result(nil)
        }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "texture-update-failed",
                              message: "Failed to update texture: \(error)",
                              details: nil))
        }
      }
    }
  }

  private func handleDispose(call: FlutterMethodCall, result: FlutterResult) {
    guard
      let args = call.arguments as? [String: Any],
      let textureId = args["textureId"] as? Int64,
      let texture = managedTextures.removeValue(forKey: textureId)
    else {
      result(FlutterError(code: "invalid-argument",
                          message: "disposeTexture expects a valid textureId",
                          details: nil))
      return
    }

    texture.reset()
    textures.unregisterTexture(textureId)
    result(nil)
  }
}
