#include <metal_stdlib>
#include "Shared.metalh"

using namespace metal;

// Mellow riff on ZnW's Voronoi Wave, converted from ShaderToy to Metal
// Original: https://www.shadertoy.com/view/3lfyDB

// Constants
constant int POINTS = 16; // Point rows are determined like N / 10, from bottom to up
constant float WAVE_OFFSET = 12000.0;
constant float SPEED = 1.0 / 12.0;
constant float COLOR_SPEED = 1.0 / 4.0;
constant float BRIGHTNESS = 1.2;

// Voronoi function
void voronoi(float2 uv, thread float3 &col, float time) {
    float3 voronoi = float3(0.0);
    float adjustedTime = (time + WAVE_OFFSET) * SPEED; // Vary time offset to affect wave pattern
    float bestDistance = 999.0;
    float lastBestDistance = bestDistance; // Used for Bloom & Outline
    
    for (int i = 0; i < POINTS; i++) {
        float fi = float(i);
        float2 p = float2(fmod(fi, 1.0) * 0.1 + sin(fi),
                        -0.05 + 0.15 * float(i / 10) + cos(fi + adjustedTime * cos(uv.x * 0.025)));
        float d = distance(uv, p);
        if (d < bestDistance) {
            lastBestDistance = bestDistance;
            bestDistance = d;
            
            // Two colored gradients for voronoi color variation
            voronoi.x = p.x;
            voronoi.yz = float2(p.x * 0.4 + p.y, p.y) * float2(0.9, 0.87);
        }
    }
    
    col *= 0.68 + 0.19 * voronoi; // Mix voronoi effect and default color gradient
    col += smoothstep(0.99, 1.05, 1.0 - abs(bestDistance - lastBestDistance)) * 0.9; // Outline
    col += smoothstep(0.95, 1.01, 1.0 - abs(bestDistance - lastBestDistance)) * 0.1 * col; // Outline fade border
    col += (voronoi) * 0.1 * smoothstep(0.5, 1.0, 1.0 - abs(bestDistance - lastBestDistance)); // Bloom
}

fragment float4 voronoiWave(VertexOut interpolated [[stage_in]],
                          constant Uniforms &uniforms [[buffer(0)]]) {
    // Normalized pixel coordinates (from 0 to 1)
    float2 uv = interpolated.texCoord;

    // Time varying pixel color
    float3 col = 0.5 + 0.5 * cos(uniforms.time * COLOR_SPEED + float3(uv.x, uv.y, uv.x) + float3(0, 2, 4));
    
    // Effect looks nice on this uv scaling
    voronoi(uv * 4.0 - 1.0, col, uniforms.time);

    // Output to screen
    return float4(col, 1.0) * BRIGHTNESS;
} 