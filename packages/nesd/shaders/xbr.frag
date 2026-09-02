#version 460 core
#include <flutter/runtime_effect.glsl>

// Pattern-matching upscaler in the spirit of xBR (algorithm by Hyllian).
// Each fragment sits in one quadrant of a 2x2 texel block. The corner of
// that quadrant is cut along a 45 degree line when the two texels meeting
// it diagonally form an edge that continues past the block. Flat areas and
// straight edges stay at nearest-neighbor, keeping the result sharp.

uniform vec2 uOutputSize;
uniform vec2 uSourceSize;
uniform vec4 uSourceRect;

uniform sampler2D uSource;

out vec4 fragColor;

const vec3 lumaWeights = vec3(0.299, 0.587, 0.114);
const vec3 chromaUWeights = vec3(-0.169, -0.331, 0.5);
const vec3 chromaVWeights = vec3(0.5, -0.419, -0.081);

/// Luma-dominant YUV distance, so edge detection follows brightness steps
/// rather than hue steps within a palette.
float colorDistance(vec3 a, vec3 b) {
  vec3 delta = a - b;

  return abs(dot(delta, lumaWeights)) * 48.0 +
         abs(dot(delta, chromaUWeights)) * 7.0 +
         abs(dot(delta, chromaVWeights)) * 6.0;
}

/// 1 when two texels read as the same region, 0 when they read as an edge.
float similarity(vec3 a, vec3 b) {
  return 1.0 - smoothstep(2.0, 6.0, colorDistance(a, b));
}

vec3 sampleTexel(vec2 index) {
  vec2 clamped = clamp(index + 0.5, vec2(0.5), uSourceRect.zw - 0.5);

  return texture(uSource, (uSourceRect.xy + clamped) / uSourceSize).rgb;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uOutputSize;
  vec2 coord = uv * uSourceRect.zw - 0.5;

  vec2 base = floor(coord);
  vec2 f = coord - base;

  vec3 a = sampleTexel(base);
  vec3 b = sampleTexel(base + vec2(1.0, 0.0));
  vec3 c = sampleTexel(base + vec2(0.0, 1.0));
  vec3 d = sampleTexel(base + vec2(1.0, 1.0));

  vec3 aboveA = sampleTexel(base + vec2(0.0, -1.0));
  vec3 aboveB = sampleTexel(base + vec2(1.0, -1.0));
  vec3 leftA = sampleTexel(base + vec2(-1.0, 0.0));
  vec3 rightB = sampleTexel(base + vec2(2.0, 0.0));
  vec3 leftC = sampleTexel(base + vec2(-1.0, 1.0));
  vec3 rightD = sampleTexel(base + vec2(2.0, 1.0));
  vec3 belowC = sampleTexel(base + vec2(0.0, 2.0));
  vec3 belowD = sampleTexel(base + vec2(1.0, 2.0));

  float cutA = similarity(b, c) *
      (1.0 - similarity(aboveA, b)) *
      (1.0 - similarity(leftA, c));
  float cutB = similarity(a, d) *
      (1.0 - similarity(a, aboveB)) *
      (1.0 - similarity(d, rightB));
  float cutC = similarity(a, d) *
      (1.0 - similarity(a, leftC)) *
      (1.0 - similarity(d, belowC));
  float cutD = similarity(b, c) *
      (1.0 - similarity(b, rightD)) *
      (1.0 - similarity(c, belowD));

  float right = step(0.5, f.x);
  float lower = step(0.5, f.y);

  vec3 nearest = mix(
    mix(a, b, right),
    mix(c, d, right),
    lower
  );

  float scale = min(
    uOutputSize.x / uSourceRect.z,
    uOutputSize.y / uSourceRect.w
  );
  float aa = clamp(0.7 / max(scale, 0.001), 0.02, 0.3);

  float sum = f.x + f.y;
  float difference = f.x - f.y;

  float towardsBC =
      (1.0 - right) * (1.0 - lower) * cutA *
          smoothstep(0.5 - aa, 0.5 + aa, sum) +
      right * lower * cutD *
          smoothstep(0.5 - aa, 0.5 + aa, 2.0 - sum);
  float towardsAD =
      right * (1.0 - lower) * cutB *
          smoothstep(0.5 - aa, 0.5 + aa, 1.0 - difference) +
      (1.0 - right) * lower * cutC *
          smoothstep(0.5 - aa, 0.5 + aa, 1.0 + difference);

  vec3 color = mix(
    nearest,
    mix(b, c, clamp((f.y - f.x + 1.0) * 0.5, 0.0, 1.0)),
    towardsBC
  );
  color = mix(
    color,
    mix(a, d, clamp(sum * 0.5, 0.0, 1.0)),
    towardsAD
  );

  fragColor = vec4(color, 1.0);
}
