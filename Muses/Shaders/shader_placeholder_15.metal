#include <metal_stdlib>
#include "Shared.metalh"

using namespace metal;

// 15. Intersecting Lines
fragment float4 shader_placeholder_15(VertexOut interpolated [[stage_in]],
                                     constant float &time [[buffer(0)]])
{
     float2 uv = interpolated.texCoord;
     float thickness = 0.005 + 0.003 * sin(time);
     float lineX = smoothstep(thickness, -thickness, abs(uv.x - 0.5 + 0.2*cos(time*1.2))); // Vertical line
     float lineY = smoothstep(thickness, -thickness, abs(uv.y - 0.5 + 0.2*sin(time*1.5))); // Horizontal line
     float value = max(lineX, lineY);
     return float4(value, value, value, 1.0);
} 