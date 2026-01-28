#include "include/nesd_texture/nesd_texture_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>

#include "nesd_texture_plugin_private.h"

#define NESD_TEXTURE_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), nesd_texture_plugin_get_type(), \
                              NesdTexturePlugin))

struct _NesdTexturePlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(NesdTexturePlugin, nesd_texture_plugin, g_object_get_type())

// Called when a method call is received from Flutter.
static void nesd_texture_plugin_handle_method_call(
    NesdTexturePlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "createTexture") == 0 || strcmp(method, "updateTexture") == 0 ||
      strcmp(method, "disposeTexture") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_error_response_new(
        "unimplemented",
        "nesd_texture: method not implemented on Linux yet.",
        nullptr));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void nesd_texture_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(nesd_texture_plugin_parent_class)->dispose(object);
}

static void nesd_texture_plugin_class_init(NesdTexturePluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = nesd_texture_plugin_dispose;
}

static void nesd_texture_plugin_init(NesdTexturePlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  NesdTexturePlugin* plugin = NESD_TEXTURE_PLUGIN(user_data);
  nesd_texture_plugin_handle_method_call(plugin, method_call);
}

void nesd_texture_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  NesdTexturePlugin* plugin = NESD_TEXTURE_PLUGIN(
      g_object_new(nesd_texture_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "nesd_texture",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
