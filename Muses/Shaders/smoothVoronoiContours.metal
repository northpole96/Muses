#include <metal_stdlib>
#include "Shared.metalh"

using namespace metal;

// Smooth Voronoi Contours - Converted from ShaderToy to Metal
// Original: "Smooth Voronoi Contours" by Shane
// https://www.shadertoy.com/view/XtXyDH

// Standard 2x2 hash algorithm
float2 hash22(float2 p, float time) {
    // Faster, but probably doesn't disperse things as nicely as other methods
    float n = sin(dot(p, float2(41, 289)));
    p = fract(float2(2097152, 262144) * n);
    return cos(p * 6.283 + time) * 0.5;
}

// Smooth Voronoi algorithm
float smoothVoronoi(float2 p, float falloff, float time) {
    float2 ip = floor(p); 
    p -= ip;
    
    float d = 1.0, res = 0.0;
    
    for(int i = -1; i <= 2; i++) {
        for(int j = -1; j <= 2; j++) {
            float2 b = float2(i, j);
            float2 v = b - p + hash22(ip + b, time);
            
            d = max(dot(v, v), 1e-4);
            res += 1.0 / pow(d, falloff);
        }
    }
    
    return pow(1.0 / res, 0.5 / falloff);
}

// 2D function for contours
float func2D(float2 p, float time) {
    float d = smoothVoronoi(p * 2.0, 4.0, time) * 0.66 + 
              smoothVoronoi(p * 6.0, 4.0, time) * 0.34;
    
    return sqrt(d);
}

// Smooth fract function
float smoothFract(float x, float sf) {
    x = fract(x); 
    return min(x, x * (1.0 - x) * sf);
}

fragment float4 smoothVoronoiContours(VertexOut interpolated [[stage_in]],
                                    constant Uniforms &uniforms [[buffer(0)]]) {
    // Adjust coordinates to match ShaderToy
    float2 uv = (interpolated.texCoord - 0.5) * 2.0;
    // Maintain aspect ratio
    uv.x *= uniforms.resolution.x / uniforms.resolution.y;
    
    // Standard epsilon for numerical gradient
    float2 e = float2(0.001, 0); 
    
    // The 2D function value
    float f = func2D(uv, uniforms.time);
    
    // Length of the numerical gradient
    float g = length(float2(
                f - func2D(uv - e.xy, uniforms.time), 
                f - func2D(uv - e.yx, uniforms.time)
              )) / e.x;
    
    // Dividing a constant by the length of its gradient
    g = 1.0 / max(g, 0.001);
    
    // Create contours
    float freq = 12.0;
    float smoothFactor = uniforms.resolution.y * 0.0125;
    
    // Use the smooth contour version
    float c = clamp(cos(f * freq * 3.14159 * 2.0) * g * smoothFactor, 0.0, 1.0);
    
    // Coloring
    float3 col = float3(c);
    float3 col2 = float3(c * 0.64, c, c * c * 0.1);
    
    col = mix(col, col2, -uv.y + clamp(cos(f * freq * 3.14159) * 2.0, 0.0, 1.0));
    
    // Color in a couple of the contours
    f = f * freq;
    if (f > 8.5 && f < 9.5) {
        col *= float3(1.0, 0.0, 0.1);
    }
    
    // Done
    return float4(sqrt(clamp(col, 0.0, 1.0)), 1.0);
} 