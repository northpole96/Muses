#include <metal_stdlib>
#include "Shared.metalh"

using namespace metal;

// Plasma Effect Shader
fragment float4 plasma(VertexOut in [[stage_in]],
                      constant float& time [[buffer(0)]]) {
    float2 uv = in.texCoord;
    float2 p = (uv * 2.0 - 1.0) * 2.0;

    float v1 = sin(length(p) * 8.0 + time);
    float v2 = sin(p.x * 10.0 + time * 0.5);
    float v3 = sin(p.y * 10.0 + time * 0.3);

    float v = (v1 + v2 + v3) * 0.33;
    float3 color = 0.5 + 0.5 * cos(v + float3(0,2,4));

    return float4(color, 1.0);
} 