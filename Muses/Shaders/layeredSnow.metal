#include <metal_stdlib>
#include "Shared.metalh"

using namespace metal;

// Layered Snow - Converted from ShaderToy to Metal
// Creates a beautiful layered snow effect with multiple depth layers

constant float TAU = 6.28318530718;
constant float PI = 3.14159265359;
constant int START = 3;
constant int LAYERS = 7;

// Display variable functions for debugging/visualization
inline float4 displayVar(bool a) { return float4(float3(a), 1.0); }
inline float4 displayVar(float a) { return float4(float3(a), 1.0); }
inline float4 displayVar(float2 a) { return float4(a, 0.0, 1.0); }
inline float4 displayVar(float3 a) { return float4(a, 1.0); }
inline float4 displayVar(float4 a) { return float4(a.xyz, 1.0); }

// SDF operations
inline void join(thread float& a, float b) {
    a = min(a, b);
}

inline void subt(thread float& a, float b) {
    a = max(a, -b);
}

// Box SDF
inline float box(float2 p, float2 s) {
    return max((abs(p) - s).x, (abs(p) - s).y);
}

// Digit rendering function
float digit(float2 p, int d) {
    float r = 100000000.0;
    
    switch(d) {
        case 0:
            join(r, box(p, float2(0.1, 0.15)));
            subt(r, box(p, float2(0.05, 0.1)));
            break;
        case 1:
            join(r, box(p, float2(0.025, 0.15)));
            break;
        case 2:
            join(r, box(p, float2(0.1, 0.15)));
            subt(r, box(p - float2(0.15, -0.06), float2(0.2, 0.035)));
            subt(r, box(p - float2(-0.15, 0.06), float2(0.2, 0.035)));
            break;
        case 3:
            join(r, box(p, float2(0.1, 0.15)));
            subt(r, box(p - float2(-0.15, -0.06), float2(0.2, 0.035)));
            subt(r, box(p - float2(-0.15, 0.06), float2(0.2, 0.035)));
            break;
        case 4:
            join(r, box(p - float2(0.075, 0.0), float2(0.025, 0.15)));
            join(r, box(p - float2(0.0, 0.05), float2(0.1, 0.1)));
            subt(r, box(p - float2(0.0, 0.09), float2(0.05, 0.085)));
            break;
        case 5:
            join(r, box(p, float2(0.1, 0.15)));
            subt(r, box(p - float2(0.15, 0.06), float2(0.2, 0.035)));
            subt(r, box(p - float2(-0.15, -0.06), float2(0.2, 0.035)));
            break;
        case 6:
            p = -p;
            join(r, box(p - float2(0.075, 0.0), float2(0.025, 0.15)));
            join(r, box(p - float2(0.0, 0.05), float2(0.1, 0.1)));
            subt(r, box(p - float2(0.0, 0.05), float2(0.05, 0.05)));
            break;
        case 7:
            join(r, box(p - float2(0.0), float2(0.1, 0.15)));
            subt(r, box(p - float2(-0.05), float2(0.1, 0.15)));
            break;
        case 8:
            join(r, box(p - float2(0.0), float2(0.1, 0.15)));
            subt(r, box(p - float2(0.0, 0.05), float2(0.05, 0.05)));
            subt(r, box(p - float2(0.0, -0.05), float2(0.05, 0.05)));
            join(r, box(p - float2(0.0), float2(0.1, 0.025)));
            break;
        case 9:
            join(r, box(p - float2(0.075, 0.0), float2(0.025, 0.15)));
            join(r, box(p - float2(0.0, 0.05), float2(0.1, 0.1)));
            subt(r, box(p - float2(0.0, 0.05), float2(0.05, 0.05)));
            break;
    }
    
    return r;
}

// Get digit from number
inline float getDig(float num, float d) {
    float a = floor(num / pow(10.0, d));
    return a - floor(a / 10.0) * 10.0;
}

// Print number function
float print(float2 p, float num, float spacing) {
    float r = 10000.0;
    int fig = int(ceil(log2(num) / 3.32192809489)); // log base 10 conversion
    
    for(int i = 0; i < fig; i++) {
        int di = int(getDig(num, float(i)));
        join(r, digit(p + float2(i, 0) * spacing, di));
    }
    
    return r;
}

// Print frame rate
inline float3 printFR(float2 p, float iFrameRate) {
    return 1.0 - float3(step(0.0, print((p - float2(0.474, 0.25)) * 9.0, iFrameRate, 0.3)));
}

// Hash functions for noise generation
inline float hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

inline float2 hash12(float p) {
    float3 p3 = fract(float3(p, p, p) * float3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

inline float2 hash22(float2 p) {
    float3 p3 = fract(float3(p.xyx) * float3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

inline float hash21(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// Smooth hash interpolation
inline float shash(float x) {
    return mix(hash11(floor(x)), hash11(floor(x) + 1.0), fract(x));
}

// Dithering functions
float3 dither(float3 color, float2 coord, float steps) {
    float3 reduce = floor(color * steps) / steps;
    float3 error = color - reduce;
    float noise = hash21(coord);
    return reduce + step(float3(noise), error * steps) / steps;
}

inline float3 dither(float3 color, float2 coord) {
    return dither(color, coord, 256.0);
}

// Range mapping functions
inline float mRange(float ai, float aa, float bi, float ba, float x) {
    return (x - ai) / (aa - ai) * (ba - bi) + bi;
}

inline float mRange(float2 a, float2 b, float x) {
    return mRange(a.x, a.y, b.x, b.y, x);
}

inline float sRange(float i, float a, float x) {
    return x * (a - i) + i;
}

inline float sRange(float2 a, float x) {
    return sRange(a.x, a.y, x);
}

inline float eRange(float i, float a, float x) {
    return (x - i) / (a - i);
}

inline float eRange(float2 a, float x) {
    return eRange(a.x, a.y, x);
}

// Utility functions
inline float maxcomp(float2 p) { return max(p.x, p.y); }
inline float mincomp(float2 p) { return min(p.x, p.y); }
inline float atan2(float2 p) { return atan2(p.y, p.x); }

// Snow generation function
float getSnow(float2 p, float scale, float jitter, float2 softness, float2 size, 
              float4 lobes, float2 rotRate, float moveFreq, float2 moveAmp, 
              float moveRand, float2 opacity, float fill, float t) {
    
    float2 lp = fract(p * scale) - 0.5;
    float2 cell = fmod(floor(p * scale), 100.0);
    float2 flakePos = (hash22(cell) - 0.5) * jitter + 
                      sin(hash22(cell) * TAU * moveRand + t * moveFreq) * moveAmp;
    
    float o = sRange(softness, hash21(cell)) * 0.5;
    float2 hm = float2(floor(sRange(lobes.xy, hash21(cell + 5.0))), 
                       sRange(lobes.zw, hash21(cell + 3.0)));
    
    float i = sRange(size, hash21(hash22(cell))) + 
              sin(atan2(lp - flakePos) * 4.0 * hm.x + t * sRange(rotRate, hash21(cell + 10.0))) * hm.y;
    
    return hash21(hash22(cell)) < fill ? 
           sRange(opacity, hash21(cell + 7.0)) * smoothstep(i + o, i - o, length(lp - flakePos)) : 
           0.0;
}

// Main snow rendering function
float3 renderSnow(float2 fragCoord, float2 resolution, float time) {
    // Normalized pixel coordinates
    float2 uv = (fragCoord - resolution * 0.5) / resolution.y;
    float2 suv = fragCoord / resolution;
    
    // Use default mouse position (center of screen)
    float2 mouse = resolution * 0.5;
    
    // Adjust time for snow animation
    float adjustedTime = time * 0.4;
    
    float snow = 0.0;
    for(int i = -START; i < LAYERS - START; i++) {
        float scale = exp2(-float(i));
        snow += getSnow(uv / scale - adjustedTime * float2(0.2, -0.3) + float(i) * 1.141, 
                       10.0, 0.4, 
                       float2(0.0, 0.01) + (9.0 - scale - mouse.x / resolution.x) * 0.03, 
                       float2(0.0, 0.1), 
                       float4(1.0, 3.0, 0.001, 0.005), 
                       float2(20.0, 40.0), 
                       4.0, 
                       float2(0.1, 0.1), 
                       1.0, 
                       float2(0.2, 0.8), 
                       exp2(-float(i) - float(START)), 
                       adjustedTime);
    }
    
    // Add lighting effect
    float light = max(0.0, 2.0 - length(suv - 1.0)) + sRange(0.1, 0.15, 1.0 - suv.y);
    snow += light * 0.1;
    
    // Apply dithering
    float3 col = dither(float3(snow), fragCoord);
    
    return col;
}

// Fragment shader entry point
fragment float4 layeredSnow(VertexOut interpolated [[stage_in]],
                           constant Uniforms &uniforms [[buffer(0)]]) {
    // Convert texture coordinates to screen coordinates
    float2 fragCoord = interpolated.texCoord * uniforms.resolution;
    
    // Calculate color
    float3 color = renderSnow(fragCoord, uniforms.resolution, uniforms.time);
    
    return displayVar(color);
} 