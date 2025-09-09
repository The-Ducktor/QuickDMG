
import Foundation
import AppKit

extension Notification.Name {
    static let installerProgress = Notification.Name("installerProgress")
}

actor AppInstaller {
    public var progress: Double = 0.0
    public var mountedDMGPath: String?
    public var appName: String?


    func mountDMG(at path: String, to mountPoint: String) {
        progress = 0.2
        // Post a notification to report progress (avoid capturing `self` or non-Sendable callbacks)
        let progressForNotification = progress
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .installerProgress, object: nil, userInfo: ["progress": progressForNotification])
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
        var trashedPath: NSURL? // Change to NSURL?
        let fileManager = FileManager.default
        do {
            if fileManager.fileExists(atPath: path) {
                // Using `&trashedPath` and converting to `NSURL`
                try fileManager.trashItem(at: URL(fileURLWithPath: path), resultingItemURL: &trashedPath)
                print("Deleted existing app at: \(path)")
            }
        } catch {
            print("Failed to delete app: \(error)")
        }
    }
    public static func getAppName(at path: String) -> String {
        let fileManager = FileManager.default
        let appURL = URL(fileURLWithPath: path)
        do {
            let appContents = try fileManager.contentsOfDirectory(atPath: appURL.path)
            for item in appContents {
                if item.hasSuffix(".app") {
                    return item
                }
            }
            return "Application" //
        } catch {
            print("Failed to get app name: \(error)")
            return "Application"
        }

    }
    // Unmount the .dmg file
    func unmountDMG(at mountPoint: String) {
        progress = 0.9
        // Post a notification to report progress (avoid capturing `self` or non-Sendable callbacks)
        let progressForNotification = progress
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .installerProgress, object: nil, userInfo: ["progress": progressForNotification])
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
            // Post a notification to report final progress
            let progressForNotification = progress
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .installerProgress, object: nil, userInfo: ["progress": progressForNotification])
            }
        } catch {
            print("Failed to unmount the DMG: \(error)")
        }
    }

    // Copy apps, notify progress as copying happens
    func copyApps(from sourceDirectory: String, to destinationDirectory: String) {
        progress = 0.6
        // Post a notification to report progress (avoid capturing `self` or non-Sendable callbacks)
        let progressForNotification = progress
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .installerProgress, object: nil, userInfo: ["progress": progressForNotification])
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
    private func removeExtendedAttributes(at path: String) {
        // xattr -cx /Applications/Gopeed.app/
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        process.arguments = ["-c", "-x", path]

    }

    private func findFirstFile(withExtension ext: String, in directory: String) -> String? {
        let fileManager = FileManager.default
        if let enumerator = fileManager.enumerator(atPath: directory) {
            for case let file as String in enumerator {
                if file.lowercased().hasSuffix(".\(ext.lowercased())") {
                    return (directory as NSString).appendingPathComponent(file)
                }
            }
        }
        return nil
    }

    private func silentUnmountDMG(at mountPoint: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        process.arguments = ["detach", mountPoint, "-force"]

        do {
            try process.run()
            process.waitUntilExit()
            print("Silently unmounted \(mountPoint)")
        } catch {
            print("Failed to silently unmount the DMG: \(error)")
        }
    }

    public func handleDMGFile(path: String) async {
        let mountPoint = "/Volumes/tmp" + UUID().uuidString
        self.mountedDMGPath = mountPoint

        mountDMG(at: path, to: mountPoint)

        // Look for a .pkg file first
        if let pkgPath = findFirstFile(withExtension: "pkg", in: mountPoint) {
            print("Found PKG file: \(pkgPath)")
            let tempDir = FileManager.default.temporaryDirectory
            let tempPkgName = UUID().uuidString + "-" + URL(fileURLWithPath: pkgPath).lastPathComponent
            let tempPkgURL = tempDir.appendingPathComponent(tempPkgName)

            do {
                print("Copying PKG to temporary directory: \(tempPkgURL.path)")
                try FileManager.default.copyItem(atPath: pkgPath, toPath: tempPkgURL.path)

                silentUnmountDMG(at: mountPoint)
                handlePKGFile(path: tempPkgURL.path)

            } catch {
                print("Failed to copy PKG file: \(error)")
                silentUnmountDMG(at: mountPoint)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .installerProgress, object: nil, userInfo: ["progress": 0.0, "message": "PKG installation failed."])
                }
            }
        } else {
            // No .pkg found, fall back to .app logic
            print("No PKG file found, looking for .app files.")
            self.appName = AppInstaller.getAppName(at: mountPoint)
            copyApps(from: mountPoint, to: "/Applications")

            if let appName = self.appName, appName != "Application" {
                let appPath = ("/Applications" as NSString).appendingPathComponent(appName)
                print("Removing extended attributes from \(appPath)")
                removeExtendedAttributes(at: appPath)
            }

            // This unmount will post the final notification and terminate the app
            unmountDMG(at: mountPoint)
        }
    }

    public func handlePKGFile(path: String) {
        let url = URL(fileURLWithPath: path)

        self.progress = 0.5
        let progressForNotification = self.progress

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .installerProgress, object: nil, userInfo: ["progress": progressForNotification])

            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true

            NSWorkspace.shared.open(url, configuration: configuration) { _, error in
                if let error = error {
                    print("Failed to open PKG file: \(error.localizedDescription)")
                    NotificationCenter.default.post(name: .installerProgress, object: nil, userInfo: ["progress": 0.0])
                } else {
                    NotificationCenter.default.post(name: .installerProgress, object: nil, userInfo: ["progress": 1.0])
                }
            }
        }
    }
}
