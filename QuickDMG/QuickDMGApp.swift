
import SwiftUI


@main
struct QuickDMGApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 350, minHeight: 55)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("QuickDMG")
                            .font(.headline).fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
        .defaultSize(width: 400, height: 55)
        .windowResizability(.contentSize)
    }
}
