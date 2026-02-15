//
// UnifiedWave.metal
// ProductAvatarPicker
//

#include <metal_stdlib>
using namespace metal;

static half smoothstep01(half edge0, half edge1, half x) {
    half t = clamp((x - edge0) / (edge1 - edge0), 0.0h, 1.0h);
    return t * t * (3.0h - 2.0h * t);
}

static float sdSuperellipse(float2 p, float2 size, float n) {
    float2 q = abs(p) / size;
    float d = pow(pow(q.x, n) + pow(q.y, n), 1.0 / n);
    return (d - 1.0) * min(size.x, size.y);
}

static float hash21(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

[[ stitchable ]] half4 unifiedWave(
    float2 position,
    half4 color,
    float2 size,
    float time,
    float intensity,
    float2 center,
    half4 glowColor
) {
    if (color.a <= 0.0h) {
        return color;
    }

    half2 uv = half2(position / size);
    half2 delta = uv - half2(center);
    half aspectRatio = size.x / size.y;
    delta.x *= aspectRatio;
    half r = sqrt((delta.x * delta.x) + (delta.y * delta.y));

    half intensityH = half(intensity);
    half speed = 0.6h + intensityH * 1.2h;
    half density = 80.0h - intensityH * 25.0h;
    half waveSpeed = -(half(time) * speed * 10.0h);
    half waveDensity = density * r;
    half wave = cos(waveSpeed + waveDensity);
    half waveAdj = (0.5h * wave) + 0.5h;

    half centerStrength = pow(max(0.0h, 1.0h - r), 3.0h) * (0.6h + intensityH * 2.0h);
    half hole = smoothstep01(0.08h, 0.2h, r);
    half centerLuma = centerStrength * (0.8h + waveAdj) * hole;

    half edgeDist = min(min(uv.x, 1.0h - uv.x), min(uv.y, 1.0h - uv.y));
    half edgeMask = 1.0h - smoothstep01(0.02h, 0.08h, edgeDist);

    half maxRadius = min(min(half(center.x), 1.0h - half(center.x)), min(half(center.y), 1.0h - half(center.y)));
    half reach = smoothstep01(0.6h, 1.0h, r / max(maxRadius, 0.001h));
    half edgeLuma = edgeMask * reach * (0.4h + intensityH * 1.2h) * (0.6h + waveAdj);

    half luma = centerLuma + edgeLuma;
    luma = max(0.0h, luma);

    half brightness = 0.6h + intensityH * 0.6h;
    half3 gradientColor = half3(glowColor.r, glowColor.g, glowColor.b) * brightness;
    half4 finalColor = half4(gradientColor * luma, luma);
    return finalColor * color.a;
}

[[ stitchable ]] half4 charityRipple(
    float2 position,
    half4 color,
    float2 size,
    float time,
    float2 center,
    float4 phase,
    float4 wave,
    float4 glow,
    float4 shape,
    float4 egg,
    float4 noise,
    float3 baseColor,
    float3 glowColor,
    float3 ovalColor,
    float3 backgroundColor
) {
    if (color.a <= 0.0h) {
        return color;
    }

    float progress = phase.x;
    float pulse = phase.y;
    float baseEnergy = phase.z;
    float energyCurve = phase.w;

    float waveSpeedParam = wave.x;
    float waveAmpParam = wave.y;
    float brightnessBase = wave.z;
    float climaxStart = wave.w;

    float glowSizeParam = glow.x;
    float glowIntensityParam = glow.y;
    float climaxStrength = glow.z;
    float pulseStrength = glow.w;

    float blurAmount = shape.x;
    float coreWidth = shape.y;
    float coreHeight = shape.z;
    float coreRoundness = shape.w;

    float eggBottom = egg.x;
    float eggTop = egg.y;

    float noiseStrengthParam = noise.x;
    float noiseSizeParam = noise.y;

    float2 uv = position / size;
    float invAr = size.y / size.x;
    float2 p = float2(center.x - uv.x, (center.y - uv.y) * invAr);
    float eggT = smoothstep(-0.35, 0.35, p.y);
    float eggWiden = mix(eggBottom, eggTop, eggT);
    p.x /= eggWiden;

    float progressClamped = clamp(progress, 0.0, 1.0);
    float energy = smoothstep(0.0, 1.0, progressClamped);
    energy = pow(energy, max(0.01, energyCurve));
    energy = mix(baseEnergy, 1.0, energy);
    float tension = smoothstep(0.15, 0.85, progressClamped);
    float climax = smoothstep(clamp(climaxStart, 0.5, 0.99), 1.0, progressClamped);

    float breatheAmp = mix(0.015, 0.045, energy);
    float breathe = 1.0 + breatheAmp * sin(time * 1.5);
    float2 superellipseSize = float2(coreWidth, coreHeight) * breathe;
    float distToOval = sdSuperellipse(p, superellipseSize, coreRoundness);
    float dist = length(p);

    float r = -max(distToOval, 0.0);
    float waveSpeedScaled = waveSpeedParam * mix(0.8, 1.05, energy);
    float waveSignal = sin((r + time * waveSpeedScaled) / 0.067);
    float waveNorm = max(0.0, waveSignal);
    waveNorm = smoothstep(0.0, 1.0, waveNorm);
    waveNorm = pow(waveNorm, 1.5);
    float brightness = (brightnessBase * energy) + waveNorm * (waveAmpParam * energy);
    float3 rippleColor = baseColor * brightness;

    float blurScaled = mix(blurAmount * 1.15, blurAmount * 0.85, tension);
    float ovalMask = smoothstep(blurScaled, -blurScaled, distToOval);

    float glowSizeScaled = mix(glowSizeParam * 1.2, glowSizeParam * 0.9, tension);
    float glowIntensityScaled = glowIntensityParam * energy;
    glowIntensityScaled += pulse * pulseStrength;
    glowIntensityScaled += climax * climaxStrength;
    glowIntensityScaled *= breathe;
    float glowField = smoothstep(glowSizeScaled, 0.0, max(distToOval, 0.0));
    glowField = pow(glowField, 1.5) * glowIntensityScaled;

    float3 colorWithGlow = rippleColor * breathe + glowColor * glowField;
    float3 colorBeforeFade = mix(colorWithGlow, ovalColor, ovalMask);

    float fadeToBackground = smoothstep(0.35, 0.7, dist);
    float3 finalColor = mix(colorBeforeFade, backgroundColor, fadeToBackground);

    float noiseScale = 1.0 / max(noiseSizeParam, 0.001);
    float noiseField = hash21(position * noiseScale);
    float noiseStrengthScaled = noiseStrengthParam * (0.4 + 0.6 * energy);
    float3 noiseColor = float3(0.0);
    finalColor = mix(finalColor, noiseColor, noiseField * noiseStrengthScaled);

    return half4(half3(finalColor), half(1.0)) * color.a;
}
