import SwiftUI

struct Shader: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let shaderName: String
}

struct ShaderListView: View {
    let shaders: [Shader]
    @Binding var selectedShader: Shader?

    var body: some View {
        List {
            Section("Metal Shaders") {
                ForEach(shaders) { shader in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(shader.name)
                                .font(.headline)
                            Text(shader.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedShader = shader
                    }
                }
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var previewSelectedShader: Shader? = nil
        let previewShaders = [
            Shader(name: "Preview Shader 1", description: "Desc 1", shaderName: "debugShader"),
            Shader(name: "Preview Shader 2", description: "Desc 2", shaderName: "debugShader")
        ]
        var body: some View {
            ShaderListView(shaders: previewShaders, selectedShader: $previewSelectedShader)
        }
    }
    return PreviewWrapper()
}
