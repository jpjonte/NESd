#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSourceSize;
uniform vec2 uOutputSize;
uniform float uScanlineIntensity;
uniform float uMaskStrength;
uniform float uCurvature;

uniform sampler2D uSource;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / uOutputSize;

  // convert to [-1, 1]
  vec2 centered = uv * 2.0 - 1.0;

  // barrel distortion
  centered *= 1.0 + uCurvature * dot(centered, centered);

  // convert back to [0, 1]
  vec2 warped = (centered + 1.0) * 0.5;

  if (warped.x < 0.0 || warped.x > 1.0 || warped.y < 0.0 || warped.y > 1.0) {
    // out of bounds, return black
    fragColor = vec4(0.0, 0.0, 0.0, 1.0);

    return;
  }

  vec3 color = texture(uSource, warped).rgb;

  float scanWeight = 0.5 + 0.5 * cos(6.2831853 * fract(warped.y));
  color *= 1.0 - uScanlineIntensity * scanWeight;

  float column = mod(FlutterFragCoord().x, 3.0);
  vec3 mask = vec3(
    step(column, 1.0),
    step(1.0, column) * step(column, 2.0),
    step(2.0, column)
  );
  color *= mix(vec3(1.0 - uMaskStrength), vec3(1.0), mask);

  color *= 1.0 + 0.4 * (uScanlineIntensity + uMaskStrength);

  fragColor = vec4(min(color, vec3(1.0)), 1.0);
}
