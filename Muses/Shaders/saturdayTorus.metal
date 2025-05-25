#include <metal_stdlib>
#include "Shared.metalh"

using namespace metal;

// Saturday Torus - Converted from ShaderToy to Metal
// Original inspired by: https://www.istockphoto.com/photo/black-and-white-stripes-projection-on-torus-gm488221403-39181884
// License CC0

constant float PI = 3.141592654;
constant float TAU = 2.0 * PI;

// Optimized rotation matrix function
inline float2x2 rot(float a) {
    float c = cos(a);
    float s = sin(a);
    return float2x2(c, s, -s, c);
}

// Optimized positive cosine function
inline float pcos(float x) {
    return 0.5 + 0.5 * cos(x);
}

// Optimized tanh approximation
inline float tanh_approx(float x) {
    float x2 = x * x;
    return clamp(x * (27.0 + x2) / (27.0 + 9.0 * x2), -1.0, 1.0);
}

// Ray-torus intersection (optimized version)
// License: MIT, author: Inigo Quilez
float rayTorus(float3 ro, float3 rd, float2 tor) {
    float po = 1.0;
    
    float Ra2 = tor.x * tor.x;
    float ra2 = tor.y * tor.y;
    
    float m = dot(ro, ro);
    float n = dot(ro, rd);
    
    // Early bounding sphere test
    float h = n * n - m + (tor.x + tor.y) * (tor.x + tor.y);
    if (h < 0.0) return -1.0;
    
    // Quartic equation coefficients
    float k = (m - ra2 - Ra2) * 0.5;
    float k3 = n;
    float k2 = n * n + Ra2 * rd.z * rd.z + k;
    float k1 = k * n + Ra2 * ro.z * rd.z;
    float k0 = k * k + Ra2 * ro.z * ro.z - Ra2 * ra2;
    
    // Precision handling
    if (abs(k3 * (k3 * k3 - k2) + k1) < 0.01) {
        po = -1.0;
        float tmp = k1; k1 = k3; k3 = tmp;
        k0 = 1.0 / k0;
        k1 = k1 * k0;
        k2 = k2 * k0;
        k3 = k3 * k0;
    }
    
    float c2 = 2.0 * k2 - 3.0 * k3 * k3;
    float c1 = k3 * (k3 * k3 - k2) + k1;
    float c0 = k3 * (k3 * (-3.0 * k3 * k3 + 4.0 * k2) - 8.0 * k1) + 4.0 * k0;
    
    c2 /= 3.0;
    c1 *= 2.0;
    c0 /= 3.0;
    
    float Q = c2 * c2 + c0;
    float R = 3.0 * c0 * c2 - c2 * c2 * c2 - c1 * c1;
    
    h = R * R - Q * Q * Q;
    float z = 0.0;
    
    if (h < 0.0) {
        // 4 intersections
        float sQ = sqrt(Q);
        z = 2.0 * sQ * cos(acos(R / (sQ * Q)) / 3.0);
    } else {
        // 2 intersections
        float sQ = pow(sqrt(h) + abs(R), 1.0 / 3.0);
        z = sign(R) * abs(sQ + Q / sQ);
    }
    z = c2 - z;
    
    float d1 = z - 3.0 * c2;
    float d2 = z * z - 3.0 * c0;
    
    if (abs(d1) < 1.0e-4) {
        if (d2 < 0.0) return -1.0;
        d2 = sqrt(d2);
    } else {
        if (d1 < 0.0) return -1.0;
        d1 = sqrt(d1 * 0.5);
        d2 = c1 / d1;
    }
    
    float result = 1e20;
    
    // First pair of solutions
    h = d1 * d1 - z + d2;
    if (h > 0.0) {
        h = sqrt(h);
        float t1 = -d1 - h - k3; t1 = (po < 0.0) ? 2.0 / t1 : t1;
        float t2 = -d1 + h - k3; t2 = (po < 0.0) ? 2.0 / t2 : t2;
        if (t1 > 0.0) result = t1;
        if (t2 > 0.0) result = min(result, t2);
    }
    
    // Second pair of solutions
    h = d1 * d1 - z - d2;
    if (h > 0.0) {
        h = sqrt(h);
        float t1 = d1 - h - k3; t1 = (po < 0.0) ? 2.0 / t1 : t1;
        float t2 = d1 + h - k3; t2 = (po < 0.0) ? 2.0 / t2 : t2;
        if (t1 > 0.0) result = min(result, t1);
        if (t2 > 0.0) result = min(result, t2);
    }
    
    return result;
}

// Torus normal calculation
// License: MIT, author: Inigo Quilez
inline float3 torusNormal(float3 pos, float2 tor) {
    return normalize(pos * (dot(pos, pos) - tor.y * tor.y - tor.x * tor.x * float3(1.0, 1.0, -1.0)));
}

// Main color calculation function
float3 calculateColor(float2 p, float2 q, float time, float2 resolution) {
    float rdd = 2.0;
    
    // Camera setup
    float3 ro = float3(0.0, 0.75, -0.2);
    float3 la = float3(0.0, 0.0, 0.2);
    float3 up = float3(0.3, 0.0, 1.0);
    
    // Light position
    float3 lp1 = ro;
    lp1.xy = (rot(0.85) * lp1.xy);
    lp1.xz = (rot(-0.5) * lp1.xz);
    
    // Camera basis vectors
    float3 ww = normalize(la - ro);
    float3 uu = normalize(cross(up, ww));
    float3 vv = normalize(cross(ww, uu));
    float3 rd = normalize(p.x * uu + p.y * vv + rdd * ww);
    
    // Torus parameters
    float2 tor = 0.55 * float2(1.0, 0.75);
    
    // Ray-torus intersection
    float td = rayTorus(ro, rd, tor);
    float3 tpos = ro + rd * td;
    float3 tnor = -torusNormal(tpos, tor);
    float3 tref = reflect(rd, tnor);
    
    // Lighting calculations
    float3 ldif1 = lp1 - tpos;
    float ldd1 = dot(ldif1, ldif1);
    float ldl1 = sqrt(ldd1);
    float3 ld1 = ldif1 / ldl1;
    
    // Shadow ray
    float3 sro = tpos + 0.05 * tnor;
    float sd = rayTorus(sro, ld1, tor);
    float3 spos = sro + ld1 * sd;
    float3 snor = -torusNormal(spos, tor);
    
    // Shading
    float dif1 = max(dot(tnor, ld1), 0.0);
    float spe1 = pow(max(dot(tref, ld1), 0.0), 10.0);
    
    // Pattern calculation
    float r = length(tpos.xy);
    float a = atan2(tpos.y, tpos.x) - PI * tpos.z / (r + 0.5 * abs(tpos.z)) - TAU * time / 45.0;
    float s = mix(0.05, 0.5, tanh_approx(2.0 * abs(td - 0.75)));
    
    // Base colors
    float3 bcol0 = float3(0.3);
    float3 bcol1 = float3(0.025);
    float3 tcol = mix(bcol0, bcol1, smoothstep(-s, s, sin(9.0 * a)));
    
    float3 col = float3(0.0);
    
    if (td > -1.0) {
        col += tcol * mix(0.2, 1.0, dif1 / ldd1) + 0.25 * spe1;
        col *= sqrt(abs(dot(rd, tnor)));
    }
    
    // Shadow application
    if (sd < ldl1) {
        col *= mix(1.0, 0.0, pow(abs(dot(ld1, snor)), 3.0 * tanh_approx(sd)));
    }
    
    return col;
}

// Post-processing function
// License: MIT, author: Inigo Quilez
float3 postProcess(float3 col, float2 q) {
    col = clamp(col, 0.0, 1.0);
    col = pow(col, 1.0 / 2.2);
    col = col * 0.6 + 0.4 * col * col * (3.0 - 2.0 * col);
    col = mix(col, float3(dot(col, float3(0.33))), -0.4);
    col *= 0.5 + 0.5 * pow(19.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.7);
    return col;
}

// Fragment shader entry point
fragment float4 saturdayTorus(VertexOut interpolated [[stage_in]],
                             constant Uniforms &uniforms [[buffer(0)]]) {
    // Convert texture coordinates to normalized device coordinates
    float2 q = interpolated.texCoord;
    float2 p = -1.0 + 2.0 * q;
    p.x *= uniforms.resolution.x / uniforms.resolution.y;
    
    // Calculate color
    float3 col = calculateColor(p, q, uniforms.time, uniforms.resolution);
    
    // Apply post-processing
    col = postProcess(col, q);
    
    return float4(col, 1.0);
} 