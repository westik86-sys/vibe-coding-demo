#include <metal_stdlib>
using namespace metal;

#include <SwiftUI/SwiftUI_Metal.h>
using namespace SwiftUI;

static inline float saturatefV2(float x) { return clamp(x, 0.0, 1.0); }

[[ stitchable ]]
half4 prismRippleV2(float2 position,
                    SwiftUI::Layer layer,
                    float2 center,
                    float intensity,
                    float time,
                    float radius,
                    float freq,
                    float speed,
                    float falloffPower,
                    float lensAmount,
                    float rippleAmount,
                    float caBase,
                    float caWave,
                    float redSplit,
                    float blueSplit,
                    float crestR,
                    float crestG,
                    float crestB)
{
    half4 src = layer.sample(position);
    if (intensity <= 0.0001) return src;

    float2 d = position - center;
    float dist = length(d);

    float safeRadius = max(radius, 1.0);
    float m = smoothstep(safeRadius, 0.0, dist) * intensity;
    if (m <= 0.0001) return src;

    float2 dir = (dist > 1e-4) ? (d / dist) : float2(0.0, 0.0);

    float wave = sin(dist * freq - time * speed);

    float falloff = saturatefV2(1.0 - dist / safeRadius);
    falloff = pow(falloff, max(falloffPower, 0.01));

    float lens = m * falloff * lensAmount;
    float ripple = m * falloff * wave * rippleAmount;
    float2 offset = dir * (lens + ripple);

    float ca = m * falloff * (caBase + caWave * abs(wave));
    float2 caVec = dir * ca;

    half4 base = layer.sample(position + offset);

    half r = layer.sample(position + offset + caVec * redSplit).r;
    half g = base.g;
    half b = layer.sample(position + offset - caVec * blueSplit).b;

    float crest = saturatefV2(abs(wave)) * m * falloff;
    half3 crestTint = half3(half(crestR * crest), half(crestG * crest), half(crestB * crest));

    half4 outc = half4(r, g, b, base.a);
    outc.rgb += crestTint;

    return outc;
}
