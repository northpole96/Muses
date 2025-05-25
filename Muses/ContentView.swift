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
        Shader(name: "Wavy Function", description: "Animated sine wave function visualization", shaderName: "wavyFunction"),
        Shader(name: "Line Ball Waves", description: "Converted ShaderToy effect with lines and balls", shaderName: "lineBallWaves"),
        Shader(name: "Voronoi Wave", description: "Mellow riff on Voronoi Wave with colorful patterns", shaderName: "voronoiWave"),
        Shader(name: "Smooth Voronoi Contours", description: "Smooth numerical gradient contours on 2D Voronoi", shaderName: "smoothVoronoiContours"),
        Shader(name: "Saturday Torus", description: "Animated torus with black and white stripe patterns", shaderName: "saturdayTorus"),
        Shader(name: "Monterey Wannabe", description: "Layered landscape inspired by macOS Monterey wallpaper", shaderName: "montereyWannabe"),
        Shader(name: "Circular Pattern Tiling", description: "Rotating star patterns in circular tiling arrangement", shaderName: "circularPatternTiling"),
        Shader(name: "Tunnel Rings", description: "Animated tunnel with rings of points moving toward viewer", shaderName: "tunnelRings"),
        Shader(name: "Layered Snow", description: "Beautiful layered snow effect with multiple depth layers", shaderName: "layeredSnow"),
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
