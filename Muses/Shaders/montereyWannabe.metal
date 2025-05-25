#include <metal_stdlib>
#include "Shared.metalh"

using namespace metal;

// Monterey wannabe - Converted from ShaderToy to Metal
// Original: CC0 - Monterey wannabe
// Watching a few streams I enjoy the MacOS Monterey wallpaper
// I am a sucker for intense colors
// Here's my interpretation of the wallpaper in shader form

constant float PI = 3.141592654;
constant float TAU = 2.0 * PI;

// Optimized rotation matrix function
inline float2x2 rot(float a) {
    float c = cos(a);
    float s = sin(a);
    return float2x2(c, s, -s, c);
}

// HSV to RGB conversion constants
constant float4 hsv2rgb_K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);

// License: WTFPL, author: sam hocevar
inline float3 hsv2rgb(float3 c) {
    float3 p = abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www);
    return c.z * mix(hsv2rgb_K.xxx, clamp(p - hsv2rgb_K.xxx, 0.0, 1.0), c.y);
}

// Macro version for compile-time constants
#define HSV2RGB(c) (c.z * mix(hsv2rgb_K.xxx, clamp(abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www) - hsv2rgb_K.xxx, 0.0, 1.0), c.y))

// Alpha blending functions
inline float4 alphaBlend(float4 back, float4 front) {
    float w = front.w + back.w * (1.0 - front.w);
    float3 xyz = (front.xyz * front.w + back.xyz * back.w * (1.0 - front.w)) / w;
    return w > 0.0 ? float4(xyz, w) : float4(0.0);
}

inline float3 alphaBlend(float3 back, float4 front) {
    return mix(back, front.xyz, front.w);
}

// sRGB conversion
// License: Unknown, author: nmz (twitter: @stormoid)
inline float sRGB_single(float t) {
    return mix(1.055 * pow(t, 1.0 / 2.4) - 0.055, 12.92 * t, step(t, 0.0031308));
}

inline float3 sRGB(float3 c) {
    return float3(sRGB_single(c.x), sRGB_single(c.y), sRGB_single(c.z));
}

// ACES tone mapping approximation
// License: Unknown, author: Matt Taylor
inline float3 aces_approx(float3 v) {
    v = max(v, 0.0);
    v *= 0.6;
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return clamp((v * (a * v + b)) / (v * (c * v + d) + e), 0.0, 1.0);
}

// Optimized tanh approximation
inline float tanh_approx(float x) {
    float x2 = x * x;
    return clamp(x * (27.0 + x2) / (27.0 + 9.0 * x2), -1.0, 1.0);
}

// Hash function for noise
inline float hash(float2 p) {
    float a = dot(p, float2(127.1, 311.7));
    return fract(sin(a) * 43758.5453123);
}

// Value noise implementation
// License: MIT, author: Inigo Quilez
float vnoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    
    float2 u = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i + float2(0.0, 0.0));
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));
    
    float m0 = mix(a, b, u.x);
    float m1 = mix(c, d, u.x);
    float m2 = mix(m0, m1, u.y);
    
    return m2;
}

// Height factor for terrain variation
inline float heightFactor(float2 p) {
    return 2.0 * smoothstep(0.0, 1.25, abs(p.x) - 0.05) + 1.0;
}

// High-frequency fractal Brownian motion
float hifbm(float2 p) {
    float hf = heightFactor(p);
    float aa = 0.5;
    float pp = 2.0;
    
    float sum = 0.0;
    float a = 1.0;
    
    for (int i = 0; i < 5; ++i) {
        sum += a * vnoise(p);
        a *= aa;
        p *= pp;
    }
    
    return hf * sum;
}

// Low-frequency fractal Brownian motion
float lofbm(float2 p) {
    float hf = heightFactor(p);
    float aa = 0.5;
    float pp = 2.0;
    
    float sum = 0.0;
    float a = 1.0;
    
    for (int i = 0; i < 2; ++i) {
        sum += a * vnoise(p);
        a *= aa;
        p *= pp;
    }
    
    return hf * sum;
}

// Camera path offset
float3 offset(float z) {
    float a = z * 0.5;
    float2 p = float2(0.33, 0.1) * (float2(cos(a), sin(a * sqrt(2.0))) + float2(cos(a * sqrt(0.75)), sin(a * sqrt(0.5))));
    return float3(p, z);
}

// First derivative of camera path
float3 doffset(float z) {
    float eps = 0.1;
    return 0.5 * (offset(z + eps) - offset(z - eps)) / (2.0 * eps);
}

// Second derivative of camera path
float3 ddoffset(float z) {
    float eps = 0.1;
    return 0.5 * (doffset(z + eps) - doffset(z - eps)) / (2.0 * eps);
}

// Height functions
inline float hiheight(float2 p) {
    return hifbm(p) - 1.8;
}

inline float loheight(float2 p) {
    return lofbm(p) - 2.15;
}

// Plane rendering function
float4 plane(float3 ro, float3 rd, float3 pp, float3 npp, float3 off, float n) {
    float2 p = (pp - off * 2.0 * float3(1.0, 1.0, 0.0)).xy;
    
    float2 stp = float2(0.5, 0.33);
    float he = hiheight(float2(p.x, pp.z) * stp);
    float lohe = loheight(float2(p.x, pp.z) * stp);
    
    float d = p.y - he;
    float lod = p.y - lohe;
    
    float aa = distance(pp, npp) * sqrt(1.0 / 3.0);
    
    float df = tanh_approx(max(0.225 * distance(ro, pp) - 0.4, 0.0));
    float hf = mix(0.66, 1.1, df);
    float gf = tanh_approx(exp(-2.0 * lod));
    float yf = smoothstep(2.5, -1.0, pp.y);
    
    float3 acol = hsv2rgb(float3(hf, 1.0, mix(0.2, 1.0, df)));
    float3 gcol = hsv2rgb(float3(hf, 1.0, 1.0 - gf));
    
    float t = smoothstep(aa, -aa, d);
    t *= mix(1.0, yf, sqrt(df));
    t = max(t, gf * yf * yf);
    
    float3 col = float3(0.0);
    col += acol;
    col += 0.5 * gcol;
    
    return float4(col, t);
}

// Sky color function
inline float3 skyColor(float3 ro, float3 rd, float3 nrd) {
    float3 sky = HSV2RGB(float3(0.66, 0.2, 1.0));
    return sky;
}

// Main color calculation
float3 calculateColor(float3 ww, float3 uu, float3 vv, float3 ro, float2 p, float2 resolution) {
    float2 np = p + 2.0 / resolution.y;
    float rdd = 2.0;
    float3 rd = normalize(-p.x * uu + p.y * vv + rdd * ww);
    float3 nrd = normalize(-np.x * uu + np.y * vv + rdd * ww);
    
    float planeDist = 1.0 - 0.4;
    int furthest = 12;
    int fadeFrom = max(furthest - 3, 0);
    
    float fadeDist = planeDist * float(fadeFrom);
    float maxDist = planeDist * float(furthest);
    float nz = floor(ro.z / planeDist);
    
    float3 skyCol = skyColor(ro, rd, nrd);
    
    float4 acol = float4(0.0);
    float cutOff = 0.995;
    bool cutOut = false;
    
    for (int i = 1; i <= furthest; ++i) {
        float pz = planeDist * nz + planeDist * float(i);
        float pd = (pz - ro.z) / rd.z;
        float3 pp = ro + rd * pd;
        
        if (pd > 0.0 && acol.w < cutOff) {
            float3 npp = ro + nrd * pd;
            float3 off = offset(pp.z);
            float4 pcol = plane(ro, rd, pp, npp, off, nz + float(i));
            
            float fadeIn = smoothstep(maxDist, fadeDist, pd);
            float fadeOut = smoothstep(0.0, planeDist, pd);
            pcol.w *= fadeIn;
            pcol.w *= fadeOut;
            
            acol = alphaBlend(pcol, acol);
        } else {
            cutOut = true;
            acol.w = acol.w > cutOff ? 1.0 : acol.w;
            break;
        }
    }
    
    float3 col = alphaBlend(skyCol, acol);
    return col;
}

// Main effect function
float3 effect(float2 p, float2 q, float time, float2 resolution) {
    float2x2 rotation = rot(0.1);
    float z = time * 0.3333;
    float3 ro = offset(z);
    float3 dro = doffset(z);
    float3 ddro = ddoffset(z);
    dro.zy = rotation * dro.zy;
    
    float3 ww = normalize(dro);
    float3 uu = normalize(cross(normalize(float3(0.0, 1.0, 0.0) + 2.0 * ddro), ww));
    float3 vv = cross(ww, uu);
    
    float3 col = calculateColor(ww, uu, vv, ro, p, resolution);
    
    return col;
}

// Fragment shader entry point
fragment float4 montereyWannabe(VertexOut interpolated [[stage_in]],
                               constant Uniforms &uniforms [[buffer(0)]]) {
    // Convert texture coordinates to normalized device coordinates
    float2 q = interpolated.texCoord;
    float2 p = -1.0 + 2.0 * q;
    p.x *= uniforms.resolution.x / uniforms.resolution.y;
    
    // Calculate color
    float3 col = effect(p, q, uniforms.time, uniforms.resolution);
    
    // Add initial flash effect
    col += 2.0 * smoothstep(4.0, 0.0, uniforms.time + length(p - float2(0.0, 1.0)));
    
    // Apply tone mapping and color correction
    col = aces_approx(col);
    col = sRGB(col);
    
    return float4(col, 1.0);
} 