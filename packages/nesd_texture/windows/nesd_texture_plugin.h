#ifndef FLUTTER_PLUGIN_NESD_TEXTURE_PLUGIN_H_
#define FLUTTER_PLUGIN_NESD_TEXTURE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace nesd_texture {

class NesdTexturePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  NesdTexturePlugin();

  virtual ~NesdTexturePlugin();

  // Disallow copy and assign.
  NesdTexturePlugin(const NesdTexturePlugin&) = delete;
  NesdTexturePlugin& operator=(const NesdTexturePlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace nesd_texture

#endif  // FLUTTER_PLUGIN_NESD_TEXTURE_PLUGIN_H_
