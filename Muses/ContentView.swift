//
//  ContentView.swift
//  Muses
//
//  Created by Rajesh Khuntia on 05/05/25.
//

import SwiftUI

struct ContentView: View {
    // State to track the currently selected shader
    // nil means show the list, non-nil means show the preview
    @State private var selectedShader: Shader? = nil

    // Define the list of shaders here (or load from a data source)
    let shaders = [
        Shader(name: "Debug Red", description: "Simple debugging shader with red color", shaderName: "debugShader"),
        Shader(name: "Rainbow Wave", description: "A flowing rainbow wave effect", shaderName: "rainbowWave"),
        Shader(name: "Cosmic Nebula", description: "A cosmic nebula effect with stars", shaderName: "cosmicNebula"),
        Shader(name: "Plasma Effect", description: "Dynamic plasma effect with color cycling", shaderName: "plasma"),
        Shader(name: "Fractal Explorer", description: "Interactive fractal visualization", shaderName: "fractal"),
        Shader(name: "Simple Gradient", description: "Red to blue gradient", shaderName: "shader_placeholder_1"),
        Shader(name: "Checkerboard", description: "Basic checkerboard pattern", shaderName: "shader_placeholder_2"),
        Shader(name: "Basic Noise", description: "Pseudo-random noise", shaderName: "shader_placeholder_3"),
        Shader(name: "Vertical Stripes", description: "Animated vertical sine stripes", shaderName: "shader_placeholder_4"),
        Shader(name: "Horizontal Stripes", description: "Animated horizontal cosine stripes", shaderName: "shader_placeholder_5"),
        Shader(name: "Pulsating Circle", description: "A circle that grows and shrinks", shaderName: "shader_placeholder_6"),
        Shader(name: "Rotating Square", description: "A rotating square with changing colors", shaderName: "shader_placeholder_7"),
        Shader(name: "Diagonal Wave", description: "A diagonal wave pattern", shaderName: "shader_placeholder_8"),
        Shader(name: "Voronoi Basic", description: "Basic Voronoi-like cell pattern", shaderName: "shader_placeholder_9"),
        Shader(name: "Radial Gradient", description: "Green to yellow radial gradient", shaderName: "shader_placeholder_10"),
        Shader(name: "Water Ripples", description: "Simulated water surface ripples", shaderName: "shader_placeholder_11"),
        Shader(name: "Simple Glitch", description: "Basic horizontal line glitch effect", shaderName: "shader_placeholder_12"),
        Shader(name: "Waving Flag", description: "A simple waving flag effect", shaderName: "shader_placeholder_13"),
        Shader(name: "Spotlight", description: "A moving spotlight effect", shaderName: "shader_placeholder_14"),
        Shader(name: "Intersecting Lines", description: "Moving vertical and horizontal lines", shaderName: "shader_placeholder_15")
    ]

    var body: some View {
        // Conditionally show the list or the preview
        if let shader = selectedShader {
            // Show the preview for the selected shader
            ShaderPreviewView(shader: shader, selectedShader: $selectedShader)
                .transition(.opacity) // Optional transition
        } else {
            // Show the list view
            ShaderListView(shaders: shaders, selectedShader: $selectedShader)
                .transition(.opacity) // Optional transition
        }
    }
}

#Preview {
    ContentView()
}
