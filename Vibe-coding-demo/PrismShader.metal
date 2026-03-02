#include <metal_stdlib>
using namespace metal;

#include <SwiftUI/SwiftUI_Metal.h>
using namespace SwiftUI;

static inline float saturatef(float x) { return clamp(x, 0.0, 1.0); }

[[ stitchable ]]
half4 prismRipple(float2 position,
                  SwiftUI::Layer layer,
                  float2 center,
                  float intensity,
                  float time)
{
    half4 src = layer.sample(position);
    if (intensity <= 0.0001) return src;

    float2 d = position - center;
    float dist = length(d);

    // Радиус влияния как в видео (примерно “пятно под пальцем”)
    float radius = 220.0;

    // Мягкая маска
    float m = smoothstep(radius, 0.0, dist) * intensity;
    if (m <= 0.0001) return src;

    float2 dir = (dist > 1e-4) ? (d / dist) : float2(0.0, 0.0);

    // ====== КЛЮЧ “1:1” — анимированная волна по расстоянию ======
    // Частота/скорость подобраны так, чтобы появлялись “гребни” как на ролике.
    float freq  = 0.145;   // плотность колец
    float speed = 9.2;     // скорость “бегущей” волны

    // Волна: sin(dist*freq - time*speed)
    float wave = sin(dist * freq - time * speed);

    // Чем ближе к центру — тем сильнее
    float falloff = (1.0 - dist / radius);
    falloff = falloff * falloff; // чуть резче в центре

    // Базовая “линза”
    float lens = m * falloff * 20.0;

    // Амплитуда ряби (это даёт “полосатость”)
    float ripple = m * falloff * wave * 28.0;

    // Комбинируем: линза + волна
    float2 offset = dir * (lens + ripple);

    // ====== PRISM / RGB split ======
    // На видео видно, что гребни уходят в сине-красный.
    // Делаем разные смещения для R и B + небольшую “дисперсию” от wave.
    float ca = m * falloff * (8.0 + 10.0 * abs(wave)); // сильнее на гребнях
    float2 caVec = dir * ca;

    half4 base = layer.sample(position + offset);

    half r = layer.sample(position + offset + caVec * 0.95).r;
    half g = base.g;
    half b = layer.sample(position + offset - caVec * 1.10).b;

    // Доп. “спектральный гребень” — усиливает именно полосы (как на видео)
    float crest = saturatef(abs(wave)) * m * falloff;
    half3 crestTint = half3(half(0.35 * crest), half(0.10 * crest), half(0.45 * crest));

    half4 outc = half4(r, g, b, base.a);
    outc.rgb += crestTint;

    return outc;
}
