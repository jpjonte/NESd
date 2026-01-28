package dev.jpj.nesd_texture

import android.graphics.Bitmap
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.util.LongSparseArray
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.view.TextureRegistry
import java.nio.ByteBuffer

class NesdTexturePlugin : FlutterPlugin, MethodCallHandler {

  private lateinit var channel: MethodChannel
  private lateinit var textureRegistry: TextureRegistry

  private val textures = LongSparseArray<TextureWrapper>()
  private val mainHandler = Handler(Looper.getMainLooper())
  private lateinit var workerThread: HandlerThread
  private lateinit var workerHandler: Handler

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    textureRegistry = binding.textureRegistry

    workerThread = HandlerThread("nesd_texture_worker")
    workerThread.start()

    workerHandler = Handler(workerThread.looper)

    channel = MethodChannel(binding.binaryMessenger, "nesd_texture")
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)

    for (index in 0 until textures.size()) {
      textures.valueAt(index)?.release()
    }

    textures.clear()

    if (::workerThread.isInitialized) {
      workerThread.quitSafely()
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "createTexture" -> handleCreate(call, result)
      "updateTexture" -> handleUpdate(call, result)
      "disposeTexture" -> handleDispose(call, result)
      else -> result.notImplemented()
    }
  }

  private fun handleCreate(call: MethodCall, result: Result) {
    val args = call.arguments as? Map<*, *> ?: run {
      result.error("invalid-argument", "createTexture expects arguments", null)

      return
    }

    val width = (args["width"] as? Number)?.toInt() ?: run {
      result.error("invalid-argument", "createTexture missing width", null)

      return
    }

    val height = (args["height"] as? Number)?.toInt() ?: run {
      result.error("invalid-argument", "createTexture missing height", null)

      return
    }

    val producer = textureRegistry.createSurfaceProducer()

    val wrapper = TextureWrapper(producer, width, height, mainHandler)

    textures.put(producer.id(), wrapper)

    result.success(producer.id().toInt())
  }

  private fun handleUpdate(call: MethodCall, result: Result) {
    val args = call.arguments as? Map<*, *> ?: run {
      result.error("invalid-argument", "updateTexture expects arguments", null)

      return
    }

    val textureId = (args["textureId"] as? Number)?.toLong() ?: run {
      result.error("invalid-argument", "updateTexture missing textureId", null)

      return
    }

    val pixelPointer = (args["pixelPointer"] as? Number)?.toLong()
    val pixels = args["pixels"] as? ByteArray
    val length = (args["length"] as? Number)?.toInt()
      ?: pixels?.size
      ?: run {
        result.error("invalid-argument", "updateTexture missing length", null)

        return
      }

    if (pixelPointer == null && pixels == null) {
      result.error("invalid-argument", "updateTexture missing pixels", null)

      return
    }

    val texture = textures[textureId] ?: run {
      result.error("invalid-texture", "Unknown texture id $textureId", null)

      return
    }

    workerHandler.post {
      try {
        texture.update(
          pixels = pixels,
          pixelPointer = pixelPointer,
          length = length,
        )

        mainHandler.post { result.success(null) }
      } catch (error: Throwable) {
        mainHandler.post {
          result.error(
            "texture-update-failed",
            "Failed to update texture: ${error.message}",
            null,
          )
        }
      }
    }
  }

  private fun handleDispose(call: MethodCall, result: Result) {
    val args = call.arguments as? Map<*, *> ?: run {
      result.error("invalid-argument", "disposeTexture expects arguments", null)

      return
    }

    val textureId = (args["textureId"] as? Number)?.toLong() ?: run {
      result.error("invalid-argument", "disposeTexture missing textureId", null)

      return
    }

    val texture = textures[textureId] ?: run {
      result.error("invalid-texture", "Unknown texture id $textureId", null)

      return
    }

    texture.release()

    result.success(null)
  }

  private class TextureWrapper(
    private val producer: TextureRegistry.SurfaceProducer,
    private val width: Int,
    private val height: Int,
    private val mainHandler: Handler,
  ) : TextureRegistry.SurfaceProducer.Callback {
    private val bitmapLock = Any()
    private var bitmap: Bitmap

    init {
      producer.setSize(width, height)
      producer.setCallback(this)

      bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
    }

    fun update(pixels: ByteArray?, pixelPointer: Long?, length: Int) {
      when {
        pixelPointer != null -> updateFromPointer(pixelPointer, length)
        pixels != null -> updateFromBytes(pixels)
        else -> throw IllegalArgumentException("Missing pixel data")
      }
    }

    private fun updateFromPointer(pixelPointer: Long, length: Int) {
      synchronized(bitmapLock) {
        NativeBindings.copyPixelsToBitmap(bitmap, pixelPointer, length)

        draw()
      }
    }

    private fun updateFromBytes(pixels: ByteArray) {
      val buffer = ByteBuffer.wrap(pixels)
      synchronized(bitmapLock) {
        bitmap.copyPixelsFromBuffer(buffer)

        draw()
      }
    }

    fun release() {
      if (Looper.myLooper() == Looper.getMainLooper()) {
        cleanup()
      } else {
        mainHandler.post { cleanup() }
      }
    }

    override fun onSurfaceAvailable() {
      synchronized(bitmapLock) {
        draw()
      }
    }

    private fun draw() {
      val canvas = producer.surface.lockHardwareCanvas()

      try {
        canvas.drawBitmap(bitmap, 0.0f, 0.0f, null)
      } finally {
        producer.surface.unlockCanvasAndPost(canvas)
      }
    }

    private fun cleanup() {
      synchronized(bitmapLock) {
        producer.release()

        bitmap.recycle()
      }
    }
  }
}
