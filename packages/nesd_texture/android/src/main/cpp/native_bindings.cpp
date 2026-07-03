#include <android/bitmap.h>
#include <android/native_window.h>
#include <android/native_window_jni.h>
#include <jni.h>

#include <algorithm>
#include <cstdint>
#include <cstring>

namespace {

void ThrowRuntimeException(JNIEnv* env, const char* message) {
  auto exception_class = env->FindClass("java/lang/RuntimeException");

  if (exception_class != nullptr) {
    env->ThrowNew(exception_class, message);
  }
}

}  // namespace

extern "C" JNIEXPORT void JNICALL
Java_dev_jpj_nesd_1texture_NativeBindings_copyPixelsToBitmap(
    JNIEnv* env,
    jobject /*thiz*/,
    jobject bitmap,
    jlong source_pointer,
    jint length) {
  if (bitmap == nullptr || source_pointer == 0 || length <= 0) {
    ThrowRuntimeException(env, "Invalid bitmap or source pointer.");

    return;
  }

  AndroidBitmapInfo info{};
  if (AndroidBitmap_getInfo(env, bitmap, &info) != ANDROID_BITMAP_RESULT_SUCCESS) {
    ThrowRuntimeException(env, "Unable to query bitmap info.");

    return;
  }

  if (info.format != ANDROID_BITMAP_FORMAT_RGBA_8888) {
    ThrowRuntimeException(env, "Bitmap format must be RGBA8888.");

    return;
  }

  void* destination = nullptr;
  if (AndroidBitmap_lockPixels(env, bitmap, &destination) != ANDROID_BITMAP_RESULT_SUCCESS) {
    ThrowRuntimeException(env, "Unable to lock bitmap pixels.");

    return;
  }

  const auto available = static_cast<size_t>(info.height) * info.stride;
  const auto copy_length = std::min(available, static_cast<size_t>(length));

  auto* source = reinterpret_cast<void*>(static_cast<intptr_t>(source_pointer));
  std::memcpy(destination, source, copy_length);

  AndroidBitmap_unlockPixels(env, bitmap);
}

extern "C" JNIEXPORT jboolean JNICALL
Java_dev_jpj_nesd_1texture_NativeBindings_copyPixelsToSurface(
    JNIEnv* env,
    jobject /*thiz*/,
    jobject surface,
    jlong source_pointer,
    jint width,
    jint height) {
  if (surface == nullptr || source_pointer == 0 || width <= 0 || height <= 0) {
    return JNI_FALSE;
  }

  ANativeWindow* window = ANativeWindow_fromSurface(env, surface);
  if (window == nullptr) {
    return JNI_FALSE;
  }

  if (ANativeWindow_setBuffersGeometry(window, width, height,
                                       WINDOW_FORMAT_RGBA_8888) != 0) {
    ANativeWindow_release(window);

    return JNI_FALSE;
  }

  ANativeWindow_Buffer buffer{};
  if (ANativeWindow_lock(window, &buffer, nullptr) != 0) {
    ANativeWindow_release(window);

    return JNI_FALSE;
  }

  const auto* source = reinterpret_cast<const uint8_t*>(
      static_cast<intptr_t>(source_pointer));
  auto* destination = static_cast<uint8_t*>(buffer.bits);

  const auto source_row = static_cast<size_t>(width) * 4;
  // ANativeWindow_Buffer.stride is in pixels, not bytes
  const auto destination_row = static_cast<size_t>(buffer.stride) * 4;
  const int rows = height < buffer.height ? height : buffer.height;

  if (buffer.stride == width) {
    std::memcpy(destination, source, source_row * rows);
  } else {
    for (int y = 0; y < rows; y++) {
      std::memcpy(destination + y * destination_row,
                  source + y * source_row,
                  source_row);
    }
  }

  ANativeWindow_unlockAndPost(window);
  ANativeWindow_release(window);

  return JNI_TRUE;
}
