#include "include/nesd_texture/nesd_texture_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#include <cstring>

#define NESD_TEXTURE_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), nesd_texture_plugin_get_type(), \
                              NesdTexturePlugin))

G_DECLARE_FINAL_TYPE(NesdTexture, nesd_texture, NESD, TEXTURE,
                     FlPixelBufferTexture)

struct _NesdTexture {
  FlPixelBufferTexture parent_instance;

  uint32_t width;
  uint32_t height;

  GMutex latest_mutex;
  uint8_t* latest;

  uint8_t* present;
};

G_DEFINE_TYPE(NesdTexture, nesd_texture, fl_pixel_buffer_texture_get_type())

static gboolean nesd_texture_copy_pixels(FlPixelBufferTexture* texture,
                                         const uint8_t** out_buffer,
                                         uint32_t* width, uint32_t* height,
                                         GError** error) {
  NesdTexture* self = NESD_TEXTURE(texture);

  g_mutex_lock(&self->latest_mutex);
  memcpy(self->present, self->latest,
         static_cast<size_t>(self->width) * self->height * 4);
  g_mutex_unlock(&self->latest_mutex);

  *out_buffer = self->present;
  *width = self->width;
  *height = self->height;

  return TRUE;
}

static void nesd_texture_finalize(GObject* object) {
  NesdTexture* self = NESD_TEXTURE(object);

  g_mutex_clear(&self->latest_mutex);
  g_clear_pointer(&self->latest, g_free);
  g_clear_pointer(&self->present, g_free);

  G_OBJECT_CLASS(nesd_texture_parent_class)->finalize(object);
}

static void nesd_texture_class_init(NesdTextureClass* klass) {
  FL_PIXEL_BUFFER_TEXTURE_CLASS(klass)->copy_pixels = nesd_texture_copy_pixels;
  G_OBJECT_CLASS(klass)->finalize = nesd_texture_finalize;
}

static void nesd_texture_init(NesdTexture* self) {
  g_mutex_init(&self->latest_mutex);
}

static NesdTexture* nesd_texture_new(uint32_t width, uint32_t height) {
  NesdTexture* self =
      NESD_TEXTURE(g_object_new(nesd_texture_get_type(), nullptr));

  size_t size = static_cast<size_t>(width) * height * 4;

  self->width = width;
  self->height = height;
  self->latest = static_cast<uint8_t*>(g_malloc0(size));
  self->present = static_cast<uint8_t*>(g_malloc0(size));

  return self;
}

struct _NesdTexturePlugin {
  GObject parent_instance;

  FlTextureRegistrar* texture_registrar;

  GHashTable* textures;

  GPtrArray* retired;
};

G_DEFINE_TYPE(NesdTexturePlugin, nesd_texture_plugin, g_object_get_type())

static bool get_int_arg(FlValue* args, const char* name, int64_t* out) {
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    return false;
  }

  FlValue* value = fl_value_lookup_string(args, name);

  if (value == nullptr || fl_value_get_type(value) != FL_VALUE_TYPE_INT) {
    return false;
  }

  *out = fl_value_get_int(value);

  return true;
}

static FlMethodResponse* handle_create(NesdTexturePlugin* self, FlValue* args) {
  int64_t width = 0;
  int64_t height = 0;

  if (!get_int_arg(args, "width", &width) ||
      !get_int_arg(args, "height", &height) || width <= 0 || height <= 0) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "invalid-argument", "createTexture expects width and height", nullptr));
  }

  g_autoptr(NesdTexture) texture = nesd_texture_new(
      static_cast<uint32_t>(width), static_cast<uint32_t>(height));

  if (!fl_texture_registrar_register_texture(self->texture_registrar,
                                             FL_TEXTURE(texture))) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "texture-registration-failed", "Failed to register texture", nullptr));
  }

  int64_t texture_id = fl_texture_get_id(FL_TEXTURE(texture));

  gint64* key = g_new(gint64, 1);
  *key = texture_id;
  g_hash_table_insert(self->textures, key, g_object_ref(texture));

  g_autoptr(FlValue) result = fl_value_new_int(texture_id);

  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static FlMethodResponse* handle_update(NesdTexturePlugin* self, FlValue* args) {
  int64_t texture_id = 0;
  int64_t width = 0;
  int64_t height = 0;
  int64_t length = 0;

  if (!get_int_arg(args, "textureId", &texture_id) ||
      !get_int_arg(args, "width", &width) ||
      !get_int_arg(args, "height", &height) ||
      !get_int_arg(args, "length", &length)) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "invalid-argument",
        "updateTexture expects textureId, width, height, and length",
        nullptr));
  }

  NesdTexture* texture = static_cast<NesdTexture*>(
      g_hash_table_lookup(self->textures, &texture_id));

  if (texture == nullptr) {
    g_autofree gchar* message =
        g_strdup_printf("Unknown texture id %" G_GINT64_FORMAT, texture_id);

    return FL_METHOD_RESPONSE(
        fl_method_error_response_new("invalid-texture", message, nullptr));
  }

  const uint8_t* source = nullptr;

  int64_t pixel_pointer = 0;

  if (get_int_arg(args, "pixelPointer", &pixel_pointer) &&
      pixel_pointer != 0) {
    source = reinterpret_cast<const uint8_t*>(
        static_cast<uintptr_t>(pixel_pointer));
  } else {
    FlValue* pixels = fl_value_lookup_string(args, "pixels");

    if (pixels != nullptr &&
        fl_value_get_type(pixels) == FL_VALUE_TYPE_UINT8_LIST) {
      source = fl_value_get_uint8_list(pixels);
      length = static_cast<int64_t>(fl_value_get_length(pixels));
    }
  }

  if (source == nullptr) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "invalid-argument", "updateTexture missing pixels", nullptr));
  }

  if (width != texture->width || height != texture->height) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "texture-update-failed", "Texture dimensions do not match", nullptr));
  }

  int64_t required = static_cast<int64_t>(texture->width) * texture->height * 4;

  if (length < required) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "texture-update-failed", "Pixel buffer too small", nullptr));
  }

  g_mutex_lock(&texture->latest_mutex);
  memcpy(texture->latest, source, static_cast<size_t>(required));
  g_mutex_unlock(&texture->latest_mutex);

  fl_texture_registrar_mark_texture_frame_available(self->texture_registrar,
                                                    FL_TEXTURE(texture));

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

static FlMethodResponse* handle_dispose(NesdTexturePlugin* self,
                                        FlValue* args) {
  int64_t texture_id = 0;

  if (!get_int_arg(args, "textureId", &texture_id)) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "invalid-argument", "disposeTexture expects textureId", nullptr));
  }

  NesdTexture* texture = static_cast<NesdTexture*>(
      g_hash_table_lookup(self->textures, &texture_id));

  if (texture == nullptr) {
    g_autofree gchar* message =
        g_strdup_printf("Unknown texture id %" G_GINT64_FORMAT, texture_id);

    return FL_METHOD_RESPONSE(
        fl_method_error_response_new("invalid-texture", message, nullptr));
  }

  fl_texture_registrar_unregister_texture(self->texture_registrar,
                                          FL_TEXTURE(texture));

  gpointer key = nullptr;
  gpointer retired = nullptr;

  if (g_hash_table_steal_extended(self->textures, &texture_id, &key,
                                  &retired)) {
    g_free(key);
    g_ptr_array_add(self->retired, retired);
  }

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

static void nesd_texture_plugin_handle_method_call(
    NesdTexturePlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  if (strcmp(method, "createTexture") == 0) {
    response = handle_create(self, args);
  } else if (strcmp(method, "updateTexture") == 0) {
    response = handle_update(self, args);
  } else if (strcmp(method, "disposeTexture") == 0) {
    response = handle_dispose(self, args);
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void nesd_texture_plugin_dispose(GObject* object) {
  NesdTexturePlugin* self = NESD_TEXTURE_PLUGIN(object);

  if (self->textures != nullptr) {
    GHashTableIter iter;
    gpointer value;

    g_hash_table_iter_init(&iter, self->textures);

    while (g_hash_table_iter_next(&iter, nullptr, &value)) {
      fl_texture_registrar_unregister_texture(self->texture_registrar,
                                              FL_TEXTURE(value));
    }

    g_clear_pointer(&self->textures, g_hash_table_unref);
  }

  g_clear_pointer(&self->retired, g_ptr_array_unref);

  g_clear_object(&self->texture_registrar);

  G_OBJECT_CLASS(nesd_texture_plugin_parent_class)->dispose(object);
}

static void nesd_texture_plugin_class_init(NesdTexturePluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = nesd_texture_plugin_dispose;
}

static void nesd_texture_plugin_init(NesdTexturePlugin* self) {
  self->textures = g_hash_table_new_full(g_int64_hash, g_int64_equal, g_free,
                                         g_object_unref);
  self->retired = g_ptr_array_new_with_free_func(g_object_unref);
}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  NesdTexturePlugin* plugin = NESD_TEXTURE_PLUGIN(user_data);
  nesd_texture_plugin_handle_method_call(plugin, method_call);
}

void nesd_texture_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  NesdTexturePlugin* plugin = NESD_TEXTURE_PLUGIN(
      g_object_new(nesd_texture_plugin_get_type(), nullptr));

  plugin->texture_registrar = FL_TEXTURE_REGISTRAR(
      g_object_ref(fl_plugin_registrar_get_texture_registrar(registrar)));

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
