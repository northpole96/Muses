#include <metal_stdlib>
#include "Shared.metalh"

using namespace metal;

// Cosmic Nebula Shader
fragment float4 cosmicNebula(VertexOut in [[stage_in]],
                           constant float& time [[buffer(0)]]) {
    float2 uv = in.texCoord * 2.0 - 1.0;
    float3 color = float3(0.0);

    for(float i = 1.0; i < 7.0; i++) {
        float2 q = uv * (2.0 + i * 0.5);
        float2 pos = float2(cos(time * 0.1 + i) * 0.5,
                          sin(time * 0.1 + i) * 0.5);
        color += 0.01 / length(q - pos);
    }

    color = pow(color, float3(0.5));
    return float4(color, 1.0);
} 