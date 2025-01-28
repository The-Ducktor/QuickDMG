import SwiftUI

class InstallationProgress: ObservableObject {
    @Published var progress: Double = 0.0
    @Published var message: String = "Starting installation..."
}

func foramtProgress(_ progress: Double, appname: String = "Application")
    -> String
{

    if progress > 0.2 && progress < 0.8 {
        return "Copying \"\(appname)\"..."
    } else if progress > 0.8 {
        return "Finishing up..."
    } else if progress < 0.2 {
        return "Mounting DMG..."
    }
    return "Starting installation..."
}
struct ContentView: View {
    @State private var currentURL: String? = nil
    @ObservedObject var progress = InstallationProgress()
    @State private var nmessage: String = "Example"
    @State private var hasReceivedURL = false  // Track if we received a URL

    var progressTotal: Double = 1.0
    var installer = AppInstaller()

    var body: some View {
        VStack(spacing: 20) {

            ProgressBar(
                value: $progress.progress,
                total: progressTotal,
                message: $progress.message
            )
            .frame(height: 20)
            .padding(.horizontal)
        }

        .onOpenURL {
            url in
            hasReceivedURL = true
            startInstallation(from: url.path)

        }
        .task {
            // Delay the file picker check slightly to allow onOpenURL to process first
            try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 second delay
            if !hasReceivedURL {
                openFilePicker()
            }
        }
        .padding(.bottom)

    }

    // Combined installation logic
    private func startInstallation(from path: String) {
        currentURL = path
        progress.message = "Starting installation from: \(path)"
        progress.progress = 0.0

        DispatchQueue.global(qos: .background).async {
            installer.handleDMGFile(path: path) { currentProgress in
                DispatchQueue.main.async {
                    print("Progress updated: \(currentProgress)")
                    progress.progress = currentProgress
                    progress.message = foramtProgress(
                        currentProgress,
                        appname: installer.appName ?? "Applicaton"
                    )

                    if currentProgress == 1.0 {
                        progress.message = "Installation Complete!"
                        NSApplication.shared.terminate(nil)
                    }
                }
            }
        }
    }

    private func openFilePicker() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.diskImage]
        openPanel.allowsMultipleSelection = false

        if openPanel.runModal() == .OK, let url = openPanel.urls.first {
            startInstallation(from: url.path)
        } else {
            NSApplication.shared.terminate(nil)
        }
    }
}

#Preview {
    ContentView()
}
