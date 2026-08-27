#version 460 core
#include <flutter/runtime_effect.glsl>

// The leading vec2 must stay first: when this shader runs as an
// ImageFilter over the GPU texture path, the engine writes the input
// texture size into the first two floats.
uniform vec2 uOutputSize;
uniform vec2 uSourceSize;

uniform sampler2D uSource;

out vec4 fragColor;

vec4 sampleSource(vec2 texelCenter) {
  vec2 clamped = clamp(texelCenter, vec2(0.5), uSourceSize - 0.5);

  return texture(uSource, clamped / uSourceSize);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uOutputSize;
  vec2 texel = uv * uSourceSize - 0.5;

  vec2 base = floor(texel) + 0.5;
  vec2 f = texel - floor(texel);

  // sharp bilinear
  vec2 scale = max(floor(uOutputSize / uSourceSize), vec2(1.0));
  vec2 sharp = clamp(f * scale - (scale - 1.0) * 0.5, 0.0, 1.0);

  vec4 c00 = sampleSource(base);
  vec4 c10 = sampleSource(base + vec2(1.0, 0.0));
  vec4 c01 = sampleSource(base + vec2(0.0, 1.0));
  vec4 c11 = sampleSource(base + vec2(1.0, 1.0));

  fragColor = mix(
    mix(c00, c10, sharp.x),
    mix(c01, c11, sharp.x),
    sharp.y
  );
}
