import SwiftUI
import MetalKit
import AppKit // Import AppKit for NSWindow

struct ShaderPreviewView: View {
    let shader: Shader
    @Binding var selectedShader: Shader?
    
    var body: some View {
        ZStack {
            MetalView(shaderName: shader.shaderName)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Button(action: {
                        selectedShader = nil
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(.leading)

                    Spacer()
                }
                .padding(.top)
                Spacer()
            }
        }
    }
}

struct MetalView: NSViewRepresentable {
    let shaderName: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
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
        mtkView.preferredFramesPerSecond = 60
        
        context.coordinator.setupMetal(mtkView: mtkView)
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        // Update if needed
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        var parent: MetalView
        var device: MTLDevice!
        var commandQueue: MTLCommandQueue!
        var pipelineState: MTLRenderPipelineState!
        var vertexBuffer: MTLBuffer!
        var time: Float = 0
        
        init(_ parent: MetalView) {
            self.parent = parent
            super.init()
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
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Handle resize if needed
        }
        
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let commandBuffer = commandQueue.makeCommandBuffer(),
                  let renderPassDescriptor = view.currentRenderPassDescriptor,
                  let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                return
            }
            
            time += 0.016 // Approximately 60 FPS
            
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.setFragmentBytes(&time, length: MemoryLayout<Float>.stride, index: 0)
            
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            
            renderEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
} 