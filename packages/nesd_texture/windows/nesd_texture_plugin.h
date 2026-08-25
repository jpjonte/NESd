#ifndef FLUTTER_PLUGIN_NESD_TEXTURE_PLUGIN_H_
#define FLUTTER_PLUGIN_NESD_TEXTURE_PLUGIN_H_

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/texture_registrar.h>

#include <cstdint>
#include <map>
#include <memory>
#include <mutex>
#include <vector>

namespace nesd_texture {

class NesdTexture {
 public:
  NesdTexture(size_t width, size_t height);

  NesdTexture(const NesdTexture&) = delete;
  NesdTexture& operator=(const NesdTexture&) = delete;

  size_t width() const { return width_; }
  size_t height() const { return height_; }
  flutter::TextureVariant* texture() { return &texture_; }

  void Update(const uint8_t* source);

 private:
  const FlutterDesktopPixelBuffer* CopyPixelBuffer();

  const size_t width_;
  const size_t height_;

  std::mutex latest_mutex_;
  std::vector<uint8_t> latest_;

  std::vector<uint8_t> present_;
  FlutterDesktopPixelBuffer pixel_buffer_{};

  flutter::TextureVariant texture_;
};

class NesdTexturePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  explicit NesdTexturePlugin(flutter::TextureRegistrar* texture_registrar);

  virtual ~NesdTexturePlugin();

  NesdTexturePlugin(const NesdTexturePlugin&) = delete;
  NesdTexturePlugin& operator=(const NesdTexturePlugin&) = delete;

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

 private:
  void HandleCreate(
      const flutter::EncodableMap* args,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void HandleUpdate(
      const flutter::EncodableMap* args,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void HandleDispose(
      const flutter::EncodableMap* args,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);

  flutter::TextureRegistrar* texture_registrar_;
  std::map<int64_t, std::unique_ptr<NesdTexture>> textures_;
};

}  // namespace nesd_texture

#endif  // FLUTTER_PLUGIN_NESD_TEXTURE_PLUGIN_H_
