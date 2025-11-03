package dev.jpj.nesd_texture

import android.graphics.Bitmap
import android.os.Handler
import android.os.Looper
import android.util.LongSparseArray
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.view.TextureRegistry

class NesdTexturePlugin : FlutterPlugin, MethodCallHandler {

  private lateinit var channel: MethodChannel
  private lateinit var textureRegistry: TextureRegistry

  private val textures = LongSparseArray<TextureWrapper>()
  private val mainHandler = Handler(Looper.getMainLooper())

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    textureRegistry = binding.textureRegistry

    channel = MethodChannel(binding.binaryMessenger, "nesd_texture")
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)

    for (index in 0 until textures.size()) {
      textures.valueAt(index)?.release()
    }

    textures.clear()
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

    val pixels = args["pixels"] as? ByteArray ?: run {
      result.error("invalid-argument", "updateTexture missing pixels", null)

      return
    }

    val texture = textures[textureId] ?: run {
      result.error("invalid-texture", "Unknown texture id $textureId", null)

      return
    }

    try {
      texture.update(pixels)

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
    private var scratch: IntArray
    private val bitmapLock = Any()
    private var bitmap: Bitmap

    init {
      producer.setSize(width, height)
      producer.setCallback(this)

      bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)

      scratch = IntArray(width * height)
    }

    fun update(pixels: ByteArray) {
      var src = 0

      for (i in scratch.indices) {
        val r = pixels[src].toInt() and 0xFF
        val g = pixels[src + 1].toInt() and 0xFF
        val b = pixels[src + 2].toInt() and 0xFF
        val a = pixels[src + 3].toInt() and 0xFF

        scratch[i] = (a shl 24) or (r shl 16) or (g shl 8) or b
        src += 4
      }

      synchronized(bitmapLock) {
        bitmap.setPixels(scratch, 0, width, 0, 0, width, height)

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
