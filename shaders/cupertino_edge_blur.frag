#version 460 core
#include <flutter/runtime_effect.glsl>

// One separable pass of the iOS 26 scroll-edge progressive blur, applied as
// a BackdropFilter image filter (ui.ImageFilter.shader). Run twice — once
// with u_blur_direction (1,0), once (0,1) — stacked, for a full Gaussian.
//
// The sigma falls off continuously from the screen edge (quadratic), so the
// blur has no visible steps; sampling is masked to the effect's own
// rectangle (u_area_*) so pixels outside the page — e.g. the black gap
// revealed while back-swiping a route — can never smear in.

// Maximum taps per side. Must be a compile-time constant (SkSL loops);
// larger radii are covered by widening the stride, not adding taps.
#define MAX_TAPS 64
#define MAX_TAPS_F 64.0

// Sigma below which the blur is invisible and skipped.
#define MIN_SIGMA 1.0e-2

// Guards the normalization against division by zero.
#define MIN_WEIGHT 1.0e-5

uniform vec2 u_size;           // floats 0,1 — filled by the engine
uniform sampler2D u_texture;   // sampler 0 — the backdrop, bound by the engine

uniform float u_blur_sigma;    // 2 — peak sigma at the screen edge, device px
uniform vec2 u_blur_direction; // 3,4 — (1,0) horizontal pass, (0,1) vertical
uniform vec2 u_area_origin;    // 5,6 — effect rect origin, device px (screen space)
uniform vec2 u_area_size;      // 7,8 — effect rect size, device px
uniform float u_edge;          // 9 — 0: strongest at the area's top; 1: at its bottom

out vec4 frag_color;

void main() {
  vec2 xy = FlutterFragCoord().xy;
  vec2 uv = xy / u_size;
  vec2 texel = 1.0 / u_size;

  vec2 areaTopLeftUV = u_area_origin / u_size;
  vec2 areaBottomRightUV = (u_area_origin + u_area_size) / u_size;

  vec4 bg = texture(u_texture, uv);

  // Vertical position within the effect area: 0 at its top, 1 at its bottom.
  float t = clamp((xy.y - u_area_origin.y) / max(u_area_size.y, 1.0), 0.0, 1.0);
  // Distance from the hugged screen edge: 0 at the edge, 1 fully inward.
  // The last 3% is a dead zone (sigma exactly 0) so the filter's boundary
  // never coincides with a live blur: where it does, taps past the edge are
  // masked away and the surviving taps — all from brighter content above —
  // leave a faint light line exactly at the end of the effect.
  float edgeDist = clamp(mix(t, 1.0 - t, u_edge) / 0.97, 0.0, 1.0);
  // Cosine falloff, raised to soften the knee: full strength at the edge,
  // still visibly blurred through the middle, easing to exactly zero with
  // zero slope at the inner boundary. A plain quadratic collapses by the
  // halfway point, which is what made the effect read as a band that stops
  // rather than a blur that fades.
  float falloff = pow(cos(edgeDist * 1.5707963), 1.5);

  float sigma = u_blur_sigma * falloff;
  if (sigma < MIN_SIGMA) {
    frag_color = bg;
    return;
  }

  float invTwoSigma2 = 1.0 / (2.0 * sigma * sigma);
  // Radius approximated as 3 * sigma (~99% of the Gaussian's weight).
  float radius = ceil(3.0 * sigma);
  // Wider stride instead of more taps when the radius exceeds the tap budget.
  float stride = max(1.0, radius / MAX_TAPS_F);
  vec2 texelStep = texel * u_blur_direction * stride;

  float totalWeight = 0.0;
  vec4 totalColor = vec4(0.0);

  for (int i = 0; i <= MAX_TAPS; i++) {
    float x = float(i) * stride;
    if (x > radius) break;

    float weight = exp(-(x * x) * invTwoSigma2);

    if (i == 0) {
      totalColor += bg * weight;
      totalWeight += weight;
    } else {
      vec2 offset = texelStep * float(i);
      vec2 uvRaw1 = uv + offset;
      vec2 uvRaw2 = uv - offset;

      // Taps outside the effect area contribute nothing — the page's own
      // edge pixels never mix with whatever lies beyond it on screen.
      float mask1 =
          step(areaTopLeftUV.x, uvRaw1.x) * step(uvRaw1.x, areaBottomRightUV.x) *
          step(areaTopLeftUV.y, uvRaw1.y) * step(uvRaw1.y, areaBottomRightUV.y);
      float mask2 =
          step(areaTopLeftUV.x, uvRaw2.x) * step(uvRaw2.x, areaBottomRightUV.x) *
          step(areaTopLeftUV.y, uvRaw2.y) * step(uvRaw2.y, areaBottomRightUV.y);

      vec2 uv1 = clamp(uvRaw1, areaTopLeftUV, areaBottomRightUV);
      vec2 uv2 = clamp(uvRaw2, areaTopLeftUV, areaBottomRightUV);

      float w1 = weight * mask1;
      float w2 = weight * mask2;

      totalColor += texture(u_texture, uv1) * w1 + texture(u_texture, uv2) * w2;
      totalWeight += w1 + w2;
    }
  }

  frag_color = totalColor / max(totalWeight, MIN_WEIGHT);
}
