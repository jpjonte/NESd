package dev.jpj.nesd_texture

import android.graphics.Bitmap
import android.view.Surface

internal object NativeBindings {

  init {
    System.loadLibrary("nesd_texture_native")
  }

  external fun copyPixelsToBitmap(bitmap: Bitmap, sourcePointer: Long, length: Int)

  external fun copyPixelsToSurface(
    surface: Surface,
    sourcePointer: Long,
    width: Int,
    height: Int,
  ): Boolean
}
