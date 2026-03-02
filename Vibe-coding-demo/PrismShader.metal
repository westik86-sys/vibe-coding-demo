#include <metal_stdlib>
using namespace metal;

#include <SwiftUI/SwiftUI_Metal.h>
using namespace SwiftUI;

// stitchable layer effect:
// position      — координата текущего пикселя
// args          — SwiftUI layer (.sampleNearest / .sampleLinear)
// center (vec2) — точка касания
// intensity (f) — 0…1

[[ stitchable ]] half4 prism(
    float2 position,
    SwiftUI::Layer layer,
    float2 center,
    float intensity
) {
    // Вектор от центра касания к текущему пикселю
    float2 delta = position - center;
    float dist = length(delta);

    // Радиус линзы
    float radius = 120.0;

    // Нормализованное расстояние (0 в центре, 1 на краю)
    float t = saturate(dist / radius);

    // Гладкий спад от центра к краю (перевёрнутый smoothstep)
    float falloff = 1.0 - smoothstep(0.0, 1.0, t);

    // Общая сила эффекта
    float strength = intensity * falloff;

    // === Lens distortion (barrel) ===
    // Искривляем координаты к центру — эффект выпуклой линзы
    float lensStrength = 0.35;
    float2 lensOffset = -delta * strength * lensStrength * (1.0 - t);
    float2 distortedPos = position + lensOffset;

    // === Chromatic aberration (RGB split) ===
    // Каждый канал смещается на разную величину вдоль delta
    float chromatic = 12.0 * strength; // макс. пиксельный сдвиг
    float2 dir = (dist > 0.001) ? (delta / dist) : float2(0.0);

    float2 posR = distortedPos + dir * chromatic;
    float2 posG = distortedPos;
    float2 posB = distortedPos - dir * chromatic;

    half4 colR = layer.sample(posR);
    half4 colG = layer.sample(posG);
    half4 colB = layer.sample(posB);

    half4 result;
    result.r = colR.r;
    result.g = colG.g;
    result.b = colB.b;
    result.a = max(max(colR.a, colG.a), colB.a);

    // Лёгкий яркостный блик в центре линзы (specular-подобный)
    float highlight = pow(falloff, 3.0) * 0.18 * intensity;
    result.rgb += half3(highlight);

    return result;
}
