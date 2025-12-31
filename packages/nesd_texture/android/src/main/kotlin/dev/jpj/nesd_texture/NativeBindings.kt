package dev.jpj.nesd_texture

import android.graphics.Bitmap

internal object NativeBindings {

  init {
    System.loadLibrary("nesd_texture_native")
  }

  external fun copyPixelsToBitmap(bitmap: Bitmap, sourcePointer: Long, length: Int)
}
