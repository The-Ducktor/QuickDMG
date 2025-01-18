//
//  Helper.swift
//  QuickDMG
//
//  Created by Jackson Powell on 1/18/25.
//
import Foundation


class AppInstaller {
    public var progress: Double = 0.0
    var progressUpdate: ((Double) -> Void)?

    // Mount the .dmg file
    func mountDMG(at path: String, to mountPoint: String) {
        progress = 0.2
        DispatchQueue.main.async {
            self.progressUpdate?(self.progress) // Notify progress change on the main thread
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        process.arguments = ["attach", path, "-mountpoint", mountPoint, "-nobrowse", "-noverify"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: outputData, encoding: .utf8) {
                print("Mounting output:\n\(outputString)")
            }
            process.waitUntilExit()
        } catch {
            print("Failed to mount the DMG: \(error)")
        }
    }
    // Terminate a running app by name
            func terminateApp(named appName: String) {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
                process.arguments = ["-x", appName]

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe

                do {
                    try process.run()
                    let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
                    if let outputString = String(data: outputData, encoding: .utf8), !outputString.isEmpty {
                        let pidStrings = outputString.split(separator: "\n")
                        for pidString in pidStrings {
                            if let pid = Int(pidString) {
                                let killProcess = Process()
                                killProcess.executableURL = URL(fileURLWithPath: "/usr/bin/kill")
                                killProcess.arguments = ["-9", String(pid)]
                                try killProcess.run()
                                print("Terminated process with PID: \(pid)")
                            }
                        }
                    }
                } catch {
                    print("Failed to terminate the app: \(error)")
                }
            }

            // Delete an existing app from /Applications
            func deleteApp(at path: String) {
                let fileManager = FileManager.default
                do {
                    if fileManager.fileExists(atPath: path) {
                        try fileManager.removeItem(atPath: path)
                        print("Deleted existing app at: \(path)")
                    }
                } catch {
                    print("Failed to delete app: \(error)")
                }
            }


    // Unmount the .dmg file
    func unmountDMG(at mountPoint: String) {
        progress = 0.9
        DispatchQueue.main.async {
            self.progressUpdate?(self.progress) // Notify progress change on the main thread
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        process.arguments = ["detach", mountPoint]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: outputData, encoding: .utf8) {
                print("Unmounting output:\n\(outputString)")
            }
            process.waitUntilExit()
            progress = 1.0
            DispatchQueue.main.async {
                self.progressUpdate?(self.progress) // Notify progress change on the main thread
            }
        } catch {
            print("Failed to unmount the DMG: \(error)")
        }
    }

    // Copy apps, notify progress as copying happens
    func copyApps(from sourceDirectory: String, to destinationDirectory: String) {
        progress = 0.6
        DispatchQueue.main.async {
                   self.progressUpdate?(self.progress)
               }
        let fileManager = FileManager.default

        do {
            let contents = try fileManager.contentsOfDirectory(atPath: sourceDirectory)
            for item in contents {
                let itemPath = (sourceDirectory as NSString).appendingPathComponent(item)
                if item.hasSuffix(".app") {
                    let destinationPath = (destinationDirectory as NSString).appendingPathComponent(item)
                    if fileManager.fileExists(atPath: destinationPath) {
                        print("\(item) already exists in \(destinationDirectory). Checking if running.")
                        terminateApp(named: item)
                        deleteApp(at: destinationPath)
                    }

                    print("Copying \(item) to \(destinationDirectory)")
                    try fileManager.copyItem(atPath: itemPath, toPath: destinationPath)
                }
            }
        } catch {
            print("Failed to copy .app files: \(error)")
        }
    }

    public func handleDMGFile(path: String, progressUpdate: @escaping (Double) -> Void) {
        self.progressUpdate = progressUpdate
        let mountPoint = "/Volumes/tmp"
        
        mountDMG(at: path, to: mountPoint)
        copyApps(from: mountPoint, to: "/Applications")
        unmountDMG(at: mountPoint)
    }
}
