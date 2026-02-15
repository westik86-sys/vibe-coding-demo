#ifndef SharedTypes_h
#define SharedTypes_h

#import <simd/simd.h>

enum BufferIndex
{
    BufferIndexParticles = 0,
    BufferIndexViewportSize = 1,
};

struct Particle
{
    simd_float2 position;
    float size;
    simd_float4 color;
};

#endif /* SharedTypes_h */
