
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var installer = AppInstaller()
    @State private var hasReceivedURL = false

    var body: some View {
        VStack(spacing: 20) {
            ProgressBar(
                value: $installer.progress,
                total: 1.0,
                message: $installer.message
            )
            .frame(height: 20)
            .padding(.horizontal)
        }


        .onOpenURL { url in
            hasReceivedURL = true
            startInstallation(from: url)
        }
        .task {
            // Short delay to see if onOpenURL fires
            try? await Task.sleep(nanoseconds: 500_000_000)
            if !hasReceivedURL {
                openFilePicker()
            }
        }
        .onChange(of: installer.progress) { oldValue, newValue in
            if newValue >= 1.0 {
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding(.bottom)
    }


    private func startInstallation(from url: URL) {
        Task { @MainActor in
            await installer.handleFile(at: url)
        }
    }

    private func openFilePicker() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.diskImage, .package]
        openPanel.allowsMultipleSelection = false

        if openPanel.runModal() == .OK, let url = openPanel.urls.first {
            startInstallation(from: url)
        } else {
            NSApplication.shared.terminate(nil)
        }
    }
}

#Preview {
    ContentView()
}
