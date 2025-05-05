#include <metal_stdlib>
#include "Shared.metalh"

using namespace metal;

// Accepts the Uniforms struct from buffer 0
fragment float4 wavyFunction(VertexOut in [[stage_in]],
                            constant Uniforms& uniforms [[buffer(0)]]) {
    // Constants
    const float Thickness = 0.025;
    const float MaxX = 3.1415926535897932384626433832795;
    const float DivMaxX = 1.0 / MaxX;
    const float3 A = float3(0.8, 0.4, 0.2);
    const float3 B = float3(0.2, 0.4, 0.8);
    const float3 C = float3(1.0, 1.0, 1.0);
    
    // Use time from uniforms
    float time = uniforms.time;
    
    // Function to calculate wave
    auto f = [time](float x) -> float {
        return 0.5 * (
                                 sin(    x - 0.3*time) 
            + 0.7*sin(0.9*time)*sin(3.0*x - 0.6*time) 
            + 0.5*sin(1.5*time)*sin(5.0*x - 0.9*time)
            + 0.3*sin(2.1*time)*sin(7.0*x - 1.2*time)
        );
    };
    
    // Use resolution from uniforms
    float2 resolution = uniforms.resolution;
    float2 fragCoord = in.texCoord * resolution;
    
    // Calculate factor for derivative using correct resolution
    float factor = resolution.x * DivMaxX * 0.5;
    
    // Function to get color at a specific coordinate
    // Capture necessary variables, including 'f' and 'factor'
    auto colorAt = [f, MaxX, DivMaxX, Thickness, A, B, C, factor](float2 coord) -> float3 {
        float y = f(coord.x);
        
        // Use Metal's dfdx for the derivative calculation
        float dy = dfdx(y) * factor;
        
        float2 p = float2(coord.x, y);
        float2 n = normalize(float2(-dy, 1.0));
        float2 delta = coord - p;
        float d = abs(dot(n, delta));
        return d > Thickness 
            ? coord.y > y 
                ? A * (1.0 + coord.y * DivMaxX) 
                : B * (1.0 - coord.y * DivMaxX) 
            : C;
    };
    
    // Main rendering - Use correct resolution
    float hps = MaxX / resolution.x;
    float2 coord = (2.0 * fragCoord - resolution) * hps;
    
    // Anti-aliasing through supersampling
    float3 color = 0.25 * (
        colorAt(coord) +
        colorAt(coord + float2(hps, 0.0)) +
        colorAt(coord + float2(0.0, hps)) +
        colorAt(coord + float2(hps, hps))
    );
    
    return float4(color, 1.0);
} 