#include <metal_stdlib>
#include "Shared.metalh" // Assuming Shared.metalh contains VertexOut and Uniforms

using namespace metal;

// --- Constants matching the GLSL globals ---
constant float3 bgColorDown = float3(0.2, 0.1, 0.1);
constant float3 bgColorUp = float3(0.1, 0.1, 0.2);

constant float3 P1ColorIn = float3(1.0, 0.5, 0.0);
constant float3 P1ColorOut = float3(1.0, 0.0, 0.0);

constant float3 P2ColorIn = float3(0.0, 0.5, 1.0);
constant float3 P2ColorOut = float3(0.0, 0.0, 1.0);
// --- End Constants ---

fragment float4 lineBallWaves(VertexOut interpolated [[stage_in]],
                             constant Uniforms &uniforms [[buffer(0)]])
{
    // coords - Use texCoord from VertexOut, assuming it's normalized [0, 1]
    float2 p = interpolated.texCoord;

    // Use uniforms for resolution and time
    float2 resolution = uniforms.resolution;
    float time = uniforms.time;

    // background
    float3 bgCol = mix(bgColorDown, bgColorUp, clamp(p.y * 2.0, 0.0, 1.0));

    // curve
    float curve = 0.1 * sin((6.25 * p.x) + (2.0 * time));

    // line A
    float lineAAnim = curve + p.y + 0.02 * sin((50.0 * p.x) + (-5.0 * time)) * sin(5.0 * (time + 0.2));
    float lineAShape = smoothstep(1.0 - clamp(abs(lineAAnim - 0.5f) * 2.0, 0.0, 1.0), 1.0, 0.99);
    float3 lineACol = (1.0 - lineAShape) * mix(P1ColorIn, P1ColorOut, lineAShape);

    // ball A - Adjusted distance calculation for Metal/normalized coords
    // Need to map p.x to [0, 1] range for the distance check if needed,
    // but keeping original logic for now assuming p is already [0,1]
    float distA = distance(p, float2(0.2, 0.5 - curve));
    // Basic aspect ratio correction attempt, adjust multiplier (0.5) as needed
    float ballAShape = smoothstep(1.0 - clamp(distA * (resolution.x / max(resolution.y, 1.0f)) * 0.5 , 0.0, 1.0), 1.0, 0.99);
    float3 ballACol = (1.0 - ballAShape) * mix(P1ColorIn, P1ColorOut, ballAShape);

    // line B
    float lineBAnim = curve + p.y + 0.02 * sin((50.0 * p.x) + (5.0 * time)) * sin(5.0 * time);
    float lineBShape = smoothstep(1.0 - clamp(abs(lineBAnim - 0.5f) * 2.0, 0.0, 1.0), 1.0, 0.99);
    float3 lineBCol = (1.0 - lineBShape) * mix(P2ColorIn, P2ColorOut, lineBShape);

    // ball B - Adjusted distance calculation
    float distB = distance(p, float2(0.8, 0.5 - curve));
     // Basic aspect ratio correction attempt, adjust multiplier (0.5) as needed
    float ballBShape = smoothstep(1.0 - clamp(distB * (resolution.x / max(resolution.y, 1.0f)) * 0.5, 0.0, 1.0), 1.0, 0.99); 
    float3 ballBCol = (1.0 - ballBShape) * mix(P2ColorIn, P2ColorOut, ballBShape);

    // final color
    float3 fcolor = bgCol + lineACol + lineBCol + ballACol + ballBCol;

    return float4(fcolor, 1.0);
} 