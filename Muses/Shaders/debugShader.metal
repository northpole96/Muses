#include <metal_stdlib>
#include "Shared.metalh"

using namespace metal;

// Debug shader - just returns red color
fragment float4 debugShader(VertexOut interpolated [[stage_in]],
                           constant float &time [[buffer(0)]]) 
{
    // Super simple - just return solid red
    return float4(1.0, 0.0, 0.0, 1.0);
} 