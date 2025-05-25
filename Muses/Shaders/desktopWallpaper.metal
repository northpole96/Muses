#include <metal_stdlib>
#include "Shared.metalh"

using namespace metal;

// Desktop Wallpaper - Converted from ShaderToy to Metal
// Fragment shader by movAX13h, Nov.2015
// Creates space invaders pattern with animated effects

// Enable invaders pattern
#define INVADERS

// Color options - can be changed for different themes
constant float3 color_blue1 = float3(0.2, 0.42, 0.68);  // blue 1
constant float3 color_mouse = float3(0.5, 0.3, 0.1);    // mouse color

// Alternative color options (commented out to avoid warnings)
// constant float3 color_blue2 = float3(0.1, 0.3, 0.6);    // blue 2
// constant float3 color_red = float3(0.6, 0.1, 0.3);      // red
// constant float3 color_green = float3(0.1, 0.6, 0.3);    // green

constant float width = 1024.0;

// Random number generation functions
inline float rand(float x) {
    return fract(sin(x) * 4358.5453);
}

inline float rand(float2 co) {
    return fract(sin(dot(co.xy, float2(12.9898, 78.233))) * 3758.5357);
}

#ifdef INVADERS
// Space invader pattern generation
float invader(float2 p, float n) {
    p.x = abs(p.x);
    p.y = -floor(p.y - 5.0);
    return step(p.x, 2.0) * step(1.0, floor(fmod(n / exp2(floor(p.x + p.y * 3.0)), 2.0)));
}
#endif

// Main wallpaper rendering function
float4 renderWallpaper(float2 fragCoord, float2 resolution, float time, bool mousePressed) {
    // Use only blue color
    float3 color = color_blue1;
    
    float2 p = fragCoord.xy;
    float2 uv = p / resolution.xy - 0.5;
    
    // Fix aspect ratio to ensure proper screen coverage
    uv.x *= resolution.x / resolution.y;
    
    float a = 0.0;
    
    // Radial gradient from center
    a -= 0.3 * smoothstep(0.0, 0.7, length(uv));
    
#ifdef INVADERS
    // Space invaders pattern - fill entire screen
    float r = rand(floor(p / 8.0));
    float inv = invader(fmod(p, 8.0) - 4.0, 809999.0 * r);
    a += (0.06 + max(0.0, 0.2 * sin(10.0 * r * time))) * inv;
#endif
    
    // Alpha based on vertical position
    float ap = p.y * 0.5;
    
    return float4(color + a, ap);
}

// Fragment shader entry point
fragment float4 desktopWallpaper(VertexOut interpolated [[stage_in]],
                                constant Uniforms &uniforms [[buffer(0)]]) {
    // Convert texture coordinates to screen coordinates
    float2 fragCoord = interpolated.texCoord * uniforms.resolution;
    
    // For mouse interaction, we'll use a time-based simulation since mouse isn't available
    // This creates a pulsing effect that changes the color periodically
    bool mousePressed = sin(uniforms.time * 0.5) > 0.0;
    
    // Calculate color
    float4 color = renderWallpaper(fragCoord, uniforms.resolution, uniforms.time, mousePressed);
    
    return color;
} 