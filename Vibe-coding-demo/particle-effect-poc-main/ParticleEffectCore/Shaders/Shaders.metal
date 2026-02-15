//
//  Shaders.metal
//  ParticleEffectCore
//
//  Created by Konstantin Moskalenko on 27.01.2026.
//

#include <metal_stdlib>
#import "SharedTypes.h"

using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float pointSize [[point_size]];
    float4 color;
};

vertex VertexOut vertexShader(uint vertexID [[vertex_id]],
                              constant Particle *particles [[buffer(BufferIndexParticles)]],
                              constant float2 &viewportSize [[buffer(BufferIndexViewportSize)]])
{
    Particle particle = particles[vertexID];
    
    float2 normalizedPosition = (particle.position / viewportSize) * 2.0 - 1.0;
    normalizedPosition.y = -normalizedPosition.y;
    
    VertexOut out;
    out.position = float4(normalizedPosition, 0.0, 1.0);
    out.pointSize = particle.size;
    out.color = particle.color;
    
    return out;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]], float2 pointCoord [[point_coord]])
{
    float2 coord = pointCoord * 2.0 - 1.0;
    float dist = length(coord) - 1.0;
    
    float edgeWidth = fwidth(dist) * 0.5;
    float alpha = 1.0 - smoothstep(-edgeWidth, edgeWidth, dist);
    
    return float4(in.color.rgb, in.color.a * alpha);
}
