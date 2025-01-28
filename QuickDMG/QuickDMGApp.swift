//
//  QuickDMGApp.swift
//  QuickDMG
//
//  Created by Jackson Powell on 1/18/25.
//

import SwiftUI

@main
struct QuickDMGApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 350).frame(height: 55)
                .toolbar {
                    // Add the title here
                    ToolbarItem(placement: .principal) {
                        Text("QuickDMG")
                            .font(.headline).fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle()) // Optional if you want hidden title bars
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
        .defaultSize(CGSize(width: 400, height: 55))
        .windowResizability(.contentSize) // Optional if you want to set the default window size
    }
}

class FileHandler: ObservableObject {
    @Published var openedFiles: [URL] = []
    
    func addFile(url: URL) {
        openedFiles.append(url)
    }
}
