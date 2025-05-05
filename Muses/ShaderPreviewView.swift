import SwiftUI
import MetalKit
import AppKit // Import AppKit for NSWindow
import simd // Import simd for float2 etc.
import Combine // Import Combine for Binding

// Swift-side struct mirroring the Metal Uniforms struct
struct Uniforms {
    var time: Float
    var resolution: float2
}

// --- Settings View ---
struct ShaderSettingsView: View {
    @Binding var showFPS: Bool
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading) {
            Text("Display Settings")
                .font(.title2)
                .padding(.bottom)

            Toggle("Show FPS Counter", isOn: $showFPS)

            Spacer()

            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
        }
        .padding()
        .frame(minWidth: 250, minHeight: 150)
    }
}

// --- Shader Preview View ---
struct ShaderPreviewView: View {
    let shader: Shader
    @Binding var selectedShader: Shader?
    
    // State for FPS display (value comes from MetalView's Coordinator)
    @State private var fps: Double = 0.0
    // Read showFPS setting from AppStorage
    @AppStorage("showFPS") var showFPS: Bool = true

    var body: some View {
        ZStack(alignment: .topLeading) { // Align controls to topLeading
            // Ensure the fps binding ($fps) is passed to MetalView
            MetalView(shaderName: shader.shaderName, fps: $fps)
                .edgesIgnoringSafeArea(.all)

            // Control Buttons (Back)
            HStack {
                // Updated Back Button
                Button { selectedShader = nil } label: {
                    Label("Back", systemImage: "chevron.left")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderedProminent)
                .tint(.black.opacity(0.6))
                .clipShape(Capsule())
                .padding([.leading, .top])
                
                Spacer()
            }

            // FPS Counter Display (Top Right) - controlled by AppStorage
            if showFPS {
                Text(String(format: "%.1f FPS", fps))
                    .font(.caption)
                    .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing) // Align to top trailing
                    .padding([.trailing, .top])
            }
        }
    }
}

struct MetalView: NSViewRepresentable {
    let shaderName: String
    @Binding var fps: Double
    // Read preferred FPS from AppStorage (now a Double)
    @AppStorage("preferredFPS") var preferredFPS: Double = 75.0

    func makeCoordinator() -> Coordinator {
        Coordinator(self, fpsBinding: $fps)
    }
    
    func makeNSView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.framebufferOnly = false
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        mtkView.drawableSize = mtkView.frame.size
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = false
        // Use preferredFPS from AppStorage, casting to Int
        mtkView.preferredFramesPerSecond = Int(preferredFPS)
        
        context.coordinator.setupMetal(mtkView: mtkView)
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        // Update preferred frame rate if the setting changes, casting to Int
        let targetFPS = Int(preferredFPS)
        if nsView.preferredFramesPerSecond != targetFPS {
             nsView.preferredFramesPerSecond = targetFPS
        }
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        var parent: MetalView
        var device: MTLDevice!
        var commandQueue: MTLCommandQueue!
        var pipelineState: MTLRenderPipelineState!
        var vertexBuffer: MTLBuffer!
        var uniformsBuffer: MTLBuffer!
        var uniforms = Uniforms(time: 0, resolution: float2(0,0))
        
        // FPS Calculation properties
        var fpsBinding: Binding<Double>
        var lastTime: CFTimeInterval = 0.0
        var frameCount: Int = 0
        let fpsUpdateInterval: TimeInterval = 0.5 // Update FPS display twice per second
        var lastFpsUpdateTime: CFTimeInterval = 0.0

        init(_ parent: MetalView, fpsBinding: Binding<Double>) {
            self.parent = parent
            self.fpsBinding = fpsBinding
            super.init()
            self.lastTime = CACurrentMediaTime() // Initialize lastTime
            self.lastFpsUpdateTime = self.lastTime
        }
        
        func setupMetal(mtkView: MTKView) {
            device = mtkView.device
            commandQueue = device.makeCommandQueue()
            
            guard let library = device.makeDefaultLibrary() as MTLLibrary? else {
                fatalError("Could not load default Metal library")
            }
            
            // Debug: Print all available functions in the library
            print("Available Metal functions:")
            for name in library.functionNames {
                print("- \(name)")
            }
            
            // Load vertex shader
            guard let vFunc = library.makeFunction(name: "vertexShader") else {
                fatalError("vertexShader not found in Metal library")
            }
            // Load fragment shader, fallback to debugShader if not found
            let fFunc: MTLFunction
            if let frag = library.makeFunction(name: parent.shaderName) {
                fFunc = frag
            } else if let debug = library.makeFunction(name: "debugShader") {
                fFunc = debug
                print("Falling back to 'debugShader' for missing shader: \(parent.shaderName)")
            } else {
                fatalError("Neither \(parent.shaderName) nor 'debugShader' found in Metal library")
            }
            
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vFunc
            pipelineDescriptor.fragmentFunction = fFunc
            pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
            
            do {
                pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            } catch {
                fatalError("Failed to create pipeline state: \(error)")
            }
            
            let vertices: [Float] = [
                -1, -1, 0, 1,
                 1, -1, 0, 1,
                -1,  1, 0, 1,
                 1,  1, 0, 1
            ]
            
            vertexBuffer = device.makeBuffer(bytes: vertices,
                                           length: vertices.count * MemoryLayout<Float>.stride,
                                           options: [])
            
            // Create uniforms buffer
            uniformsBuffer = device.makeBuffer(length: MemoryLayout<Uniforms>.stride, options: [MTLResourceOptions.storageModeShared])
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Update resolution uniform on size change
            uniforms.resolution = float2(Float(size.width), Float(size.height))
        }
        
        func draw(in view: MTKView) {
            let currentTime = CACurrentMediaTime()
            let deltaTime = currentTime - lastTime
            lastTime = currentTime
            
            frameCount += 1
            let timeSinceLastFpsUpdate = currentTime - lastFpsUpdateTime
            
            // Update FPS calculation periodically
            if timeSinceLastFpsUpdate >= fpsUpdateInterval {
                let currentFps = Double(frameCount) / timeSinceLastFpsUpdate
                // Update the binding on the main thread
                DispatchQueue.main.async {
                    self.fpsBinding.wrappedValue = currentFps
                }
                frameCount = 0
                lastFpsUpdateTime = currentTime
            }

            guard let drawable = view.currentDrawable,
                  let commandBuffer = commandQueue.makeCommandBuffer(),
                  let renderPassDescriptor = view.currentRenderPassDescriptor,
                  let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                return
            }
            
            // Update uniforms
            uniforms.time += 0.016 // Approximately 60 FPS
            if uniforms.resolution.x == 0 || uniforms.resolution.y == 0 { // Ensure resolution is set initially
                 uniforms.resolution = float2(Float(view.drawableSize.width), Float(view.drawableSize.height))
            }
            memcpy(uniformsBuffer.contents(), &uniforms, MemoryLayout<Uniforms>.stride)
            
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            // Pass uniforms buffer to fragment shader at index 0
            renderEncoder.setFragmentBuffer(uniformsBuffer, offset: 0, index: 0)
            
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            
            renderEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
} 


#Preview{
    // Create dummy data for the preview
    @State var previewSelectedShader: Shader? = Shader(name: "Test Shader", description: "A test shader.", shaderName: "wavyFunction")
    
    ShaderPreviewView(
        shader: Shader(name: "Test Shader", description: "A test shader.", shaderName: "wavyFunction"), 
        selectedShader: $previewSelectedShader
    )
}
