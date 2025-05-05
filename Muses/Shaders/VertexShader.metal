#include <metal_stdlib>
#include "Shared.metalh"

using namespace metal;

// Vertex Shader (calculates final vertex position and texture coordinates)
vertex VertexOut vertexShader(uint vertexID [[vertex_id]],
                            constant float4* positions [[buffer(0)]]) // Fixed to match actual binding
{
    float4 position = positions[vertexID];

    VertexOut out;
    out.position = position; // Pass screen position to rasterizer
    // Calculate texture coordinates (0.0 to 1.0) based on vertex position
    // Assumes quad vertices are (-1,-1), (1,-1), (-1,1), (1,1)
    out.texCoord = position.xy * 0.5 + 0.5;
    return out;
} 