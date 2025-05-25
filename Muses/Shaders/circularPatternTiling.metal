#include <metal_stdlib>
#include "Shared.metalh"

using namespace metal;

// Circular Pattern Tiling - Converted from ShaderToy to Metal
// Original: License CC0 - "Circular" Pattern Tiling
// I wanted to create "circular" tiling, turned out ok
// mod1  - From: http://mercury.sexy/hg_sdf/
// star5 - From: https://iquilezles.org/articles/distfunctions2d

constant float PI = 3.141592654;
constant float TAU = 2.0 * PI;

// Optimized mod1 function
// From: http://mercury.sexy/hg_sdf/
float mod1(thread float& p, float size) {
    float halfsize = size * 0.5;
    float c = floor((p + halfsize) / size);
    p = fmod(p + halfsize, size) - halfsize;
    return c;
}

// Convert polar to rectangular coordinates
inline float2 toRect(float2 p) {
    return p.x * float2(cos(p.y), sin(p.y));
}

// Convert rectangular to polar coordinates
inline float2 toPolar(float2 p) {
    return float2(length(p), atan2(p.y, p.x));
}

// Circular pattern tiling function
// Like many tiling functions modifies the input argument
// and returns a vector indicating which tile we are in
float3 modCircularPattern(thread float2& p) {
    float2 pp = toPolar(p);
    
    float nx = floor(pp.x + 0.5);
    pp.x -= nx;
    float ppx = pp.x;
    mod1(ppx, 1.0);
    pp.x = ppx;
    pp.x += nx;
    float cy = floor(0.5 * nx * TAU) * 2.0;
    
    float ppy = pp.y;
    float ny = mod1(ppy, TAU / cy);
    pp.y = ppy;
    if (nx > 0.0) {
        p = toRect(pp) - float2(nx, 0.0);
        return float3(nx, fmod(ny + cy * 0.5, cy), cy);
    } else {
        return float3(0.0, 0.0, 1.0);
    }
}

// Optimized rotation function
inline void rot(thread float2& p, float a) {
    float c = cos(a);
    float s = sin(a);
    p = float2(c * p.x + s * p.y, -s * p.x + c * p.y);
}

// 5-pointed star distance function
// From: https://iquilezles.org/articles/distfunctions2d
float star5(float2 p, float r, float rf) {
    float2 k1 = float2(0.809016994375, -0.587785252292);
    float2 k2 = float2(-k1.x, k1.y);
    
    p.x = abs(p.x);
    p -= 2.0 * max(dot(k1, p), 0.0) * k1;
    p -= 2.0 * max(dot(k2, p), 0.0) * k2;
    p.x = abs(p.x);
    p.y -= r;
    
    float2 ba = rf * float2(-k1.y, k1.x) - float2(0, 1);
    float h = clamp(dot(p, ba) / dot(ba, ba), 0.0, r);
    return length(p - ba * h) * sign(p.y * ba.x - p.x * ba.y);
}

// Distance field function
float df(float2 p, float time) {
    float lw = 0.033;
    
    float nx = floor(length(p) + 0.5);
    rot(p, time / sqrt(1.0 + nx));
    
    float3 n = modCircularPattern(p);
    
    rot(p, 0.1 * TAU * (n.y + n.x));
    
    float d = star5(p, 0.5 - lw, 0.5);
    d = abs(d) - lw;
    
    return d;
}

// Main color calculation for circular pattern tiling
float3 calculateCircularPatternColor(float2 p, float2 q, float time, float2 resolution) {
    float aa = 2.0 / resolution.y;
    
    float s = 0.25 * mix(0.1, 1.0, 0.5 + 0.5 * sin(time * 0.5));
    float d = df(p / s, time) * s;
    
    float3 col = mix(float3(1.0), float3(0.125), tanh(length(0.05 * p / s)));
    
    col = mix(col, float3(0.0), smoothstep(-aa, aa, -d));
    col = pow(col, float3(1.0 / 2.2));
    
    return col;
}

// Fragment shader entry point
fragment float4 circularPatternTiling(VertexOut interpolated [[stage_in]],
                                     constant Uniforms &uniforms [[buffer(0)]]) {
    // Convert texture coordinates to normalized device coordinates
    float2 q = interpolated.texCoord;
    float2 p = -1.0 + 2.0 * q;
    p.x *= uniforms.resolution.x / uniforms.resolution.y;
    
    // Scale the coordinates to match the original GLSL behavior
    p *= 2.0;
    
    // Calculate color
    float3 col = calculateCircularPatternColor(p, q, uniforms.time, uniforms.resolution);
    
    return float4(col, 1.0);
} 