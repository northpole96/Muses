#include <metal_stdlib>
#include "Shared.metalh"

using namespace metal;

// 1. Simple Gradient
fragment float4 shader_placeholder_1(VertexOut interpolated [[stage_in]],
                                    constant float &time [[buffer(0)]])
{
    float2 uv = interpolated.texCoord;
    float mixValue = 0.5 + 0.5 * sin(time + uv.x * 3.14159);
    float3 colorA = float3(1.0, 0.0, 0.0); // Red
    float3 colorB = float3(0.0, 0.0, 1.0); // Blue
    float3 color = mix(colorA, colorB, mixValue);
    return float4(color, 1.0);
} 