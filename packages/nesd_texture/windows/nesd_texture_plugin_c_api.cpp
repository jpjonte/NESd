#include "include/nesd_texture/nesd_texture_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "nesd_texture_plugin.h"

void NesdTexturePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  nesd_texture::NesdTexturePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
