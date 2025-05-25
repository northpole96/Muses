#include <metal_stdlib>
#include "Shared.metalh"

using namespace metal;

// Tunnel Rings - Converted from ShaderToy to Metal
// Creates a tunnel effect with rings of points moving toward the viewer

constant float TAU = 6.2831853071795865;

// Parameters
constant int TUNNEL_LAYERS = 96;
constant int RING_POINTS = 128;
constant float POINT_SIZE = 1.8;
constant float3 POINT_COLOR_A = float3(1.0);
constant float3 POINT_COLOR_B = float3(0.7);
constant float SPEED = 0.7;

// Square of x - optimized inline function
inline float sq(float x) {
    return x * x;
}

// Angular repeat function
float2 angRep(float2 uv, float angle) {
    float2 polar = float2(atan2(uv.y, uv.x), length(uv));
    polar.x = fmod(polar.x + angle / 2.0, angle) - angle / 2.0;
    
    return polar.y * float2(cos(polar.x), sin(polar.x));
}

// Signed distance to circle
inline float sdCircle(float2 uv, float r) {
    return length(uv) - r;
}

// Mix a shape defined by a distance field with target color
float3 mixShape(float sd, float3 fill, float3 target, float resolution_y) {
    float blend = smoothstep(0.0, 1.0 / resolution_y, sd);
    return mix(fill, target, blend);
}

// Tunnel/Camera path
float2 tunnelPath(float x) {
    float2 offs = float2(0.0);
    
    offs.x = 0.2 * sin(TAU * x * 0.5) + 0.4 * sin(TAU * x * 0.2 + 0.3);
    offs.y = 0.3 * cos(TAU * x * 0.3) + 0.2 * cos(TAU * x * 0.1);
    
    offs *= smoothstep(1.0, 4.0, x);
    
    return offs;
}

// Main tunnel rendering function
float3 renderTunnel(float2 fragCoord, float time, float2 resolution) {
    float2 res = resolution / resolution.y;
    float2 uv = fragCoord / resolution.y;
    
    uv -= res / 2.0;
    
    float3 color = float3(0.0);
    
    float repAngle = TAU / float(RING_POINTS);
    float pointSize = POINT_SIZE / 2.0 / resolution.y;
    
    float camZ = time * SPEED;
    float2 camOffs = tunnelPath(camZ);
    
    for (int i = 1; i <= TUNNEL_LAYERS; i++) {
        float pz = 1.0 - (float(i) / float(TUNNEL_LAYERS));
        
        // Scroll the points towards the screen
        pz -= fmod(camZ, 4.0 / float(TUNNEL_LAYERS));
        
        // Layer x/y offset
        float2 offs = tunnelPath(camZ + pz) - camOffs;
        
        // Radius of the current ring
        float ringRad = 0.15 * (1.0 / sq(pz * 0.8 + 0.4));
        
        // Only draw points when uv is close to the ring
        if (abs(length(uv + offs) - ringRad) < pointSize * 1.5) {
            // Angular repeated uv coords
            float2 aruv = angRep(uv + offs, repAngle);
            
            // Distance to the nearest point
            float pdist = sdCircle(aruv - float2(ringRad, 0.0), pointSize);
            
            // Stripes - alternate colors between rings
            float3 ptColor = (fmod(float(i / 2), 2.0) == 0.0) ? POINT_COLOR_A : POINT_COLOR_B;
            
            // Distance fade
            float shade = (1.0 - pz);
            
            color = mixShape(pdist, ptColor * shade, color, resolution.y);
        }
    }
    
    return color;
}

// Fragment shader entry point
fragment float4 tunnelRings(VertexOut interpolated [[stage_in]],
                           constant Uniforms &uniforms [[buffer(0)]]) {
    // Convert texture coordinates to normalized device coordinates (same as other working shaders)
    float2 q = interpolated.texCoord;
    float2 fragCoord = q * uniforms.resolution;
    
    // Calculate color using the original coordinate system
    float3 color = renderTunnel(fragCoord, uniforms.time, uniforms.resolution);
    
    return float4(color, 1.0);
} 