#include "nesd_texture_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <cstring>
#include <memory>
#include <optional>
#include <string>
#include <utility>
#include <variant>

namespace nesd_texture {

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;

std::optional<int64_t> GetIntArg(const EncodableMap* args, const char* name) {
  auto it = args->find(EncodableValue(name));

  if (it == args->end()) {
    return std::nullopt;
  }

  if (!std::holds_alternative<int32_t>(it->second) &&
      !std::holds_alternative<int64_t>(it->second)) {
    return std::nullopt;
  }

  return it->second.LongValue();
}

}  // namespace

NesdTexture::NesdTexture(size_t width, size_t height)
    : width_(width),
      height_(height),
      latest_(width * height * 4),
      present_(width * height * 4),
      texture_(flutter::PixelBufferTexture(
          [this](size_t, size_t) { return CopyPixelBuffer(); })) {}

void NesdTexture::Update(const uint8_t* source) {
  std::lock_guard<std::mutex> lock(latest_mutex_);
  std::memcpy(latest_.data(), source, latest_.size());
}

const FlutterDesktopPixelBuffer* NesdTexture::CopyPixelBuffer() {
  {
    std::lock_guard<std::mutex> lock(latest_mutex_);
    std::copy(latest_.begin(), latest_.end(), present_.begin());
  }

  pixel_buffer_.buffer = present_.data();
  pixel_buffer_.width = width_;
  pixel_buffer_.height = height_;

  return &pixel_buffer_;
}

// static
void NesdTexturePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "nesd_texture",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin =
      std::make_unique<NesdTexturePlugin>(registrar->texture_registrar());

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

NesdTexturePlugin::NesdTexturePlugin(
    flutter::TextureRegistrar* texture_registrar)
    : texture_registrar_(texture_registrar) {}

NesdTexturePlugin::~NesdTexturePlugin() {}

void NesdTexturePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto &method = method_call.method_name();

  const auto* args = std::get_if<EncodableMap>(method_call.arguments());

  if (method == "createTexture") {
    HandleCreate(args, result);
  } else if (method == "updateTexture") {
    HandleUpdate(args, result);
  } else if (method == "disposeTexture") {
    HandleDispose(args, result);
  } else {
    result->NotImplemented();
  }
}

void NesdTexturePlugin::HandleCreate(
    const EncodableMap* args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result) {
  std::optional<int64_t> width;
  std::optional<int64_t> height;

  if (args != nullptr) {
    width = GetIntArg(args, "width");
    height = GetIntArg(args, "height");
  }

  if (!width || !height || *width <= 0 || *height <= 0) {
    result->Error("invalid-argument", "createTexture expects width and height");

    return;
  }

  auto texture = std::make_unique<NesdTexture>(static_cast<size_t>(*width),
                                               static_cast<size_t>(*height));

  int64_t texture_id = texture_registrar_->RegisterTexture(texture->texture());

  if (texture_id == -1) {
    result->Error("texture-registration-failed", "Failed to register texture");

    return;
  }

  textures_[texture_id] = std::move(texture);

  result->Success(EncodableValue(texture_id));
}

void NesdTexturePlugin::HandleUpdate(
    const EncodableMap* args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result) {
  if (args == nullptr) {
    result->Error("invalid-argument", "updateTexture expects arguments");

    return;
  }

  auto texture_id = GetIntArg(args, "textureId");
  auto width = GetIntArg(args, "width");
  auto height = GetIntArg(args, "height");
  auto length = GetIntArg(args, "length");

  if (!texture_id || !width || !height || !length) {
    result->Error("invalid-argument",
                  "updateTexture expects textureId, width, height, and length");

    return;
  }

  auto it = textures_.find(*texture_id);

  if (it == textures_.end()) {
    result->Error("invalid-texture",
                  "Unknown texture id " + std::to_string(*texture_id));

    return;
  }

  NesdTexture* texture = it->second.get();

  const uint8_t* source = nullptr;

  auto pixel_pointer = GetIntArg(args, "pixelPointer");

  if (pixel_pointer && *pixel_pointer != 0) {
    source = reinterpret_cast<const uint8_t*>(
        static_cast<uintptr_t>(*pixel_pointer));
  } else {
    auto pixels_it = args->find(EncodableValue("pixels"));

    if (pixels_it != args->end()) {
      if (const auto* pixels =
              std::get_if<std::vector<uint8_t>>(&pixels_it->second)) {
        source = pixels->data();
        length = static_cast<int64_t>(pixels->size());
      }
    }
  }

  if (source == nullptr) {
    result->Error("invalid-argument", "updateTexture missing pixels");

    return;
  }

  if (static_cast<size_t>(*width) != texture->width() ||
      static_cast<size_t>(*height) != texture->height()) {
    result->Error("texture-update-failed", "Texture dimensions do not match");

    return;
  }

  int64_t required =
      static_cast<int64_t>(texture->width()) * texture->height() * 4;

  if (*length < required) {
    result->Error("texture-update-failed", "Pixel buffer too small");

    return;
  }

  texture->Update(source);

  texture_registrar_->MarkTextureFrameAvailable(*texture_id);

  result->Success();
}

void NesdTexturePlugin::HandleDispose(
    const EncodableMap* args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result) {
  std::optional<int64_t> texture_id;

  if (args != nullptr) {
    texture_id = GetIntArg(args, "textureId");
  }

  if (!texture_id) {
    result->Error("invalid-argument", "disposeTexture expects textureId");

    return;
  }

  auto it = textures_.find(*texture_id);

  if (it == textures_.end()) {
    result->Error("invalid-texture",
                  "Unknown texture id " + std::to_string(*texture_id));

    return;
  }

  // keep texture alive until the callback runs
  std::shared_ptr<NesdTexture> texture = std::move(it->second);
  textures_.erase(it);

  texture_registrar_->UnregisterTexture(*texture_id, [texture]() {});

  result->Success();
}

}  // namespace nesd_texture
