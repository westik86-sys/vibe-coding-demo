//
// PlaygroundShaders.metal
// ProductAvatarPicker
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

[[ stitchable ]] half4 msl(float2 position, SwiftUI::Layer layer, float progress) {
    float amplitude = 4;
    position.y += cos(progress + position.x / amplitude);
    return layer.sample(position);
}

[[ stitchable ]] half4 colorfilter(float2 position, SwiftUI::Layer layer, float progress) {
    half4 color = layer.sample(position);
    half luminance = dot(color.rgb, half3(0.299, 0.587, 0.114));
    half4 grayscale = half4(luminance, luminance, luminance, color.a);
    return mix(color, grayscale, progress);
}

float maprange(float value, float inMin, float inMax, float outMin, float outMax) {
    return ((value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin);
}

[[ stitchable ]] half4 distortion(float2 position, SwiftUI::Layer layer, float progress, float4 boundingRect) {
    float2 size = boundingRect.zw;
    float2 uv = position / size;

    float distortionFactor = maprange(uv.x - 0.5, -0.5, 0.5, -1.0, 1.0);
    distortionFactor *= (1.0 - uv.y);
    distortionFactor *= progress;

    uv.y += 1.3 * progress;
    uv.x += distortionFactor;

    half4 color = layer.sample(uv * size);
    return color;
}

[[ stitchable ]] half4 zoom(float2 position, SwiftUI::Layer layer, float4 boundingRect, float2 dragp, float progress) {
    float2 size = boundingRect.zw;
    float2 uv = position / size;
    float2 center = dragp / size;
    float2 delta = uv - center;
    float aspectRatio = size.x / size.y;

    float2 newdelta = delta;
    newdelta.x *= aspectRatio;

    float radius = 0.2;
    float distance = length(newdelta);
    float zoom = 1;
    if (distance < radius && progress == 1) {
        zoom = 0.8;
    }

    float2 newpos = delta * zoom + center;
    half4 color = layer.sample(newpos * size);
    return color;
}

[[ stitchable ]]
half4 Ripple(
    float2 position,
    SwiftUI::Layer layer,
    float2 origin,
    float time,
    float amplitude,
    float frequency,
    float decay,
    float speed
) {
    float distance = length(position - origin);
    float delay = distance / speed;

    time -= delay;
    time = max(0.0, time);

    float rippleAmount = amplitude * sin(frequency * time) * exp(-decay * time);

    float2 n = normalize(position - origin);
    float2 newPosition = position + rippleAmount * n;

    half4 color = layer.sample(newPosition);
    color.rgb += 0.3 * (rippleAmount / amplitude) * color.a;

    return color;
}
