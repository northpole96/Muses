import SwiftUI

struct SettingsView: View {
    // Use AppStorage to link to the same settings used elsewhere
    @AppStorage("showFPS") private var showFPS: Bool = true
    @AppStorage("preferredFPS") private var preferredFPS: Double = 75.0

    var body: some View {
        // Use a Form for standard macOS settings appearance
        Form {
            Toggle("Show FPS Counter", isOn: $showFPS)
            
            VStack(alignment: .leading) {
                Text("Maximum FPS: \(Int(preferredFPS))")
                Slider(value: $preferredFPS, in: 30.0...120.0, step: 5.0) {
                    Text("Maximum FPS") // Label for accessibility
                }
            }
            .padding(.vertical, 5) // Add a little vertical spacing
        }
        .padding(20) // Add padding around the form
        .frame(width: 350, height: 150) // Set a reasonable size for the settings window
    }
}

#Preview {
    SettingsView()
} 