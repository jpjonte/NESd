#include "nesd_texture_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>

namespace nesd_texture {

// static
void NesdTexturePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "nesd_texture",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<NesdTexturePlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

NesdTexturePlugin::NesdTexturePlugin() {}

NesdTexturePlugin::~NesdTexturePlugin() {}

void NesdTexturePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto &method = method_call.method_name();

  if (method == "createTexture" || method == "updateTexture" ||
      method == "disposeTexture") {
    result->Error("unimplemented",
                  "nesd_texture: method not implemented on Windows yet.");
  } else {
    result->NotImplemented();
  }
}

}  // namespace nesd_texture
