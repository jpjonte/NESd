#include <android/bitmap.h>
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
