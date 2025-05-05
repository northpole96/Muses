#include <metal_stdlib>
using namespace metal;

// Helper function for pseudo-random noise (2D input)
float random2D(float2 p) {
    return fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
}

// Helper function for pseudo-random noise (1D input)
float random1D(float x) {
    return fract(sin(x)*1e4);
}

struct VertexIn {
    float4 position [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut vertexShader(uint vertexID [[vertex_id]],
                            constant float4* positions [[buffer(0)]]) {
    VertexOut out;
    float4 position = positions[vertexID];
    out.position = position;
    out.texCoord = position.xy * 0.5 + 0.5;
    return out;
}

// Rainbow Wave Shader
fragment float4 rainbowWave(VertexOut in [[stage_in]],
                          constant float& time [[buffer(0)]]) {
    float2 uv = in.texCoord;
    float3 color = 0.5 + 0.5 * cos(time + uv.xyx + float3(0,2,4));
    return float4(color, 1.0);
}

// Cosmic Nebula Shader
fragment float4 cosmicNebula(VertexOut in [[stage_in]],
                           constant float& time [[buffer(0)]]) {
    float2 uv = in.texCoord * 2.0 - 1.0;
    float3 color = float3(0.0);
    
    for(float i = 1.0; i < 7.0; i++) {
        float2 q = uv * (2.0 + i * 0.5);
        float2 pos = float2(cos(time * 0.1 + i) * 0.5,
                          sin(time * 0.1 + i) * 0.5);
        color += 0.01 / length(q - pos);
    }
    
    color = pow(color, float3(0.5));
    return float4(color, 1.0);
}

// Plasma Effect Shader
fragment float4 plasma(VertexOut in [[stage_in]],
                      constant float& time [[buffer(0)]]) {
    float2 uv = in.texCoord;
    float2 p = (uv * 2.0 - 1.0) * 2.0;
    
    float v1 = sin(length(p) * 8.0 + time);
    float v2 = sin(p.x * 10.0 + time * 0.5);
    float v3 = sin(p.y * 10.0 + time * 0.3);
    
    float v = (v1 + v2 + v3) * 0.33;
    float3 color = 0.5 + 0.5 * cos(v + float3(0,2,4));
    
    return float4(color, 1.0);
}

// Fractal Shader
fragment float4 fractal(VertexOut in [[stage_in]],
                       constant float& time [[buffer(0)]]) {
    float2 uv = (in.texCoord * 2.0 - 1.0) * 2.0;
    float2 c = float2(cos(time * 0.1), sin(time * 0.1)) * 0.5;
    float2 z = uv;
    float3 color = float3(0.0);
    
    for(int i = 0; i < 100; i++) {
        z = float2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        if(length(z) > 2.0) {
            color = float3(float(i) * 0.01);
            break;
        }
    }
    
    return float4(color, 1.0);
}

// Placeholder Shaders (Replace with actual code)

// 1. Simple Gradient
fragment float4 shader_placeholder_1(VertexOut interpolated [[stage_in]],
                                    constant float &time [[buffer(0)]],
                                    float2 point [[point_coord]])
{
    float2 uv = interpolated.texCoord;
    float mixValue = 0.5 + 0.5 * sin(time + uv.x * 3.14159);
    float3 colorA = float3(1.0, 0.0, 0.0); // Red
    float3 colorB = float3(0.0, 0.0, 1.0); // Blue
    float3 color = mix(colorA, colorB, mixValue);
    return float4(color, 1.0);
}

// 2. Checkerboard Pattern
fragment float4 shader_placeholder_2(VertexOut interpolated [[stage_in]],
                                    constant float &time [[buffer(0)]],
                                    float2 point [[point_coord]])
{
    float2 uv = interpolated.texCoord;
    float scale = 10.0 + 5.0 * sin(time * 0.5);
    float check = (fmod(floor(uv.x * scale), 2.0) == 0.0 != fmod(floor(uv.y * scale), 2.0) == 0.0) ? 1.0 : 0.0;
    return float4(check, check, check, 1.0);
}

// 3. Basic Noise (Pseudo-random)
fragment float4 shader_placeholder_3(VertexOut interpolated [[stage_in]],
                                    constant float &time [[buffer(0)]],
                                    float2 point [[point_coord]])
{
    float2 uv = interpolated.texCoord;
    float noise = random2D(uv + time * 0.1);
    return float4(noise, noise, noise, 1.0);
}

// 4. Vertical Sine Stripes
fragment float4 shader_placeholder_4(VertexOut interpolated [[stage_in]],
                                    constant float &time [[buffer(0)]],
                                    float2 point [[point_coord]])
{
    float2 uv = interpolated.texCoord;
    float frequency = 15.0 + 5.0 * cos(time);
    float value = 0.5 + 0.5 * sin(uv.x * frequency + time * 2.0);
    return float4(value, value, value, 1.0);
}

// 5. Horizontal Cosine Stripes
fragment float4 shader_placeholder_5(VertexOut interpolated [[stage_in]],
                                    constant float &time [[buffer(0)]],
                                    float2 point [[point_coord]])
{
    float2 uv = interpolated.texCoord;
    float frequency = 10.0 + 4.0 * sin(time * 0.8);
    float value = 0.5 + 0.5 * cos(uv.y * frequency - time * 1.5);
    return float4(value, value, value, 1.0);
}

// 6. Pulsating Circle
fragment float4 shader_placeholder_6(VertexOut interpolated [[stage_in]],
                                    constant float &time [[buffer(0)]],
                                    float2 point [[point_coord]])
{
    float2 uv = interpolated.texCoord * 2.0 - 1.0; // Center coordinates
    float radius = 0.5 + 0.2 * sin(time * 3.0);
    float dist = length(uv);
    float circle = smoothstep(radius - 0.01, radius + 0.01, dist);
    return float4(1.0 - circle, 0.0, circle * 0.5, 1.0); // Mix red and blue
}

// 7. Rotating Color Square
fragment float4 shader_placeholder_7(VertexOut interpolated [[stage_in]],
                                    constant float &time [[buffer(0)]],
                                    float2 point [[point_coord]])
{
    float2 uv = interpolated.texCoord * 2.0 - 1.0;
    float angle = time * 0.5;
    float cosA = cos(angle);
    float sinA = sin(angle);
    float2x2 rotMat = float2x2(cosA, -sinA, sinA, cosA);
    float2 rotatedUV = uv * rotMat; // Apply rotation
    float size = 0.8;
    float square = (abs(rotatedUV.x) < size * 0.5 && abs(rotatedUV.y) < size * 0.5) ? 1.0 : 0.0;
    float3 color = 0.5 + 0.5 * cos(time + uv.xyx + float3(0, 1, 2));
    return float4(color * square, 1.0);
}

// 8. Diagonal Wave
fragment float4 shader_placeholder_8(VertexOut interpolated [[stage_in]],
                                    constant float &time [[buffer(0)]],
                                    float2 point [[point_coord]])
{
    float2 uv = interpolated.texCoord;
    float frequency = 20.0;
    float speed = 3.0;
    float value = 0.5 + 0.5 * sin((uv.x + uv.y) * frequency + time * speed);
    return float4(value * 0.8, value, value * 0.6, 1.0); // Teal-ish color
}

// 9. Simple Voronoi-like Pattern (Basic)
fragment float4 shader_placeholder_9(VertexOut interpolated [[stage_in]],
                                    constant float &time [[buffer(0)]],
                                    float2 point [[point_coord]])
{
    float2 uv = interpolated.texCoord * 5.0; // Scale UV
    float2 grid = floor(uv);
    float2 frac = fract(uv);
    float minDist = 1.0;

    for(int y = -1; y <= 1; y++) {
        for(int x = -1; x <= 1; x++) {
            float2 neighbor = float2(float(x), float(y));
            float2 pointPos = neighbor + 0.5 + 0.4 * sin(time + grid + neighbor); // Moving points
            float dist = length(frac - pointPos);
            minDist = min(minDist, dist);
        }
    }
    return float4(minDist, minDist, minDist, 1.0);
}

// 10. Radial Gradient
fragment float4 shader_placeholder_10(VertexOut interpolated [[stage_in]],
                                     constant float &time [[buffer(0)]],
                                     float2 point [[point_coord]])
{
     float2 uv = interpolated.texCoord * 2.0 - 1.0; // Center coordinates
     float dist = length(uv);
     float value = smoothstep(0.1, 0.8 + 0.2 * sin(time), dist);
     float3 colorA = float3(0.0, 1.0, 0.0); // Green
     float3 colorB = float3(1.0, 1.0, 0.0); // Yellow
     float3 color = mix(colorA, colorB, value);
     return float4(color, 1.0);
}

// 11. Water Ripples
fragment float4 shader_placeholder_11(VertexOut interpolated [[stage_in]],
                                     constant float &time [[buffer(0)]],
                                     float2 point [[point_coord]])
{
     float2 uv = interpolated.texCoord * 2.0 - 1.0;
     float dist = length(uv);
     float ripple = sin(dist * 15.0 - time * 5.0);
     float value = smoothstep(-0.2, 0.2, ripple);
     float3 color = float3(0.2, 0.5, 0.8) * value; // Blueish
     return float4(color + 0.1, 1.0); // Add base color
}

// 12. Glitch Effect (Simple)
fragment float4 shader_placeholder_12(VertexOut interpolated [[stage_in]],
                                     constant float &time [[buffer(0)]],
                                     float2 point [[point_coord]])
{
     float2 uv = interpolated.texCoord;
     float glitchAmount = sin(time * 10.0) * cos(time * 23.0) * 0.05; // Varying glitch intensity
     if (random1D(floor(uv.y * 10.0 + time * 5.0)) > 0.95) { // Horizontal glitch lines
         uv.x += random1D(uv.y * time) * glitchAmount;
     }
     float3 color = 0.5 + 0.5 * cos(time*0.5 + uv.xyx + float3(0,2,4)); // Base color (reuse rainbow)
     return float4(color, 1.0);
}

// 13. Waving Flag
fragment float4 shader_placeholder_13(VertexOut interpolated [[stage_in]],
                                     constant float &time [[buffer(0)]],
                                     float2 point [[point_coord]])
{
     float2 uv = interpolated.texCoord;
     float wave = sin(uv.x * 10.0 + time * 2.0) * 0.1; // Horizontal wave
     float wave2 = cos(uv.y * 5.0 + time * 1.0) * 0.05; // Vertical wave
     float2 wavedUV = uv + float2(wave, wave2);
     // Basic red/white stripes
     float stripe = step(0.5, fract(wavedUV.y * 5.0));
     float3 color = mix(float3(1.0, 0.1, 0.1), float3(1.0), stripe);
     return float4(color, 1.0);
}

// 14. Spotlight Effect
fragment float4 shader_placeholder_14(VertexOut interpolated [[stage_in]],
                                     constant float &time [[buffer(0)]],
                                     float2 point [[point_coord]])
{
     float2 uv = interpolated.texCoord * 2.0 - 1.0; // Center coordinates
     float2 lightPos = float2(cos(time), sin(time)) * 0.6; // Moving light source
     float dist = length(uv - lightPos);
     float intensity = smoothstep(0.8, 0.1, dist); // Inverse smoothstep for spotlight falloff
     float3 baseColor = float3(0.1, 0.1, 0.3); // Dark blue background
     float3 lightColor = float3(1.0, 1.0, 0.8); // Yellowish light
     float3 color = baseColor + lightColor * intensity;
     return float4(color, 1.0);
}

// 15. Intersecting Lines
fragment float4 shader_placeholder_15(VertexOut interpolated [[stage_in]],
                                     constant float &time [[buffer(0)]],
                                     float2 point [[point_coord]])
{
     float2 uv = interpolated.texCoord;
     float thickness = 0.005 + 0.003 * sin(time);
     float lineX = smoothstep(thickness, -thickness, abs(uv.x - 0.5 + 0.2*cos(time*1.2))); // Vertical line
     float lineY = smoothstep(thickness, -thickness, abs(uv.y - 0.5 + 0.2*sin(time*1.5))); // Horizontal line
     float value = max(lineX, lineY);
     return float4(value, value, value, 1.0);
}