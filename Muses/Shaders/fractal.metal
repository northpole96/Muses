#include <metal_stdlib>
#include "Shared.metalh"

using namespace metal;

// Fractal Shader
fragment float4 fractal(VertexOut in [[stage_in]],
                       constant float& time [[buffer(0)]]) {
    float2 uv = (in.texCoord * 2.0 - 1.0) * 2.0;
    float2 c = float2(cos(time * 0.1), sin(time * 0.1)) * 0.5;
    float2 z = uv;
    float3 color = float3(0.0);

    for(int i = 0; i < 100; i++) {
        z = float2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        if(length(z) > 2.0) {
            color = float3(float(i) * 0.01);
            break;
        }
    }

    return float4(color, 1.0);
} 