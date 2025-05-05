#include <metal_stdlib>
#include "Shared.metalh"

using namespace metal;

// Rainbow Wave Shader
fragment float4 rainbowWave(VertexOut in [[stage_in]],
                          constant float& time [[buffer(0)]]) {
    float2 uv = in.texCoord;
    float3 color = 0.5 + 0.5 * cos(time + uv.xyx + float3(0,2,4));
    return float4(color, 1.0);
} 