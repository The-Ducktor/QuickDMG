
import Foundation
import AppKit
import Observation

@Observable
@MainActor
final class AppInstaller {
    var progress: Double = 0.0
    var message: String = "Ready"
    var isInstalling: Bool = false
    var appName: String?
    
    private var currentTask: Task<Void, Never>?

    func updateProgress(_ value: Double, message: String? = nil) {
        self.progress = value
        if let message = message {
            self.message = message
        }
    }

    func handleFile(at url: URL) async {
        guard !isInstalling else { return }
        
        isInstalling = true
        progress = 0.0
        message = "Starting..."
        
        do {
            if url.pathExtension.lowercased() == "dmg" {
                try await handleDMGFile(at: url)
            } else if url.pathExtension.lowercased() == "pkg" {
                try await handlePKGFile(at: url)
            }
        } catch {
            self.message = "Error: \(error.localizedDescription)"
            self.progress = 0.0
            self.isInstalling = false
            return
        }
        
        progress = 1.0
        message = "Installation Complete!"
        isInstalling = false
    }

    private func handleDMGFile(at url: URL) async throws {
        updateProgress(0.1, message: "Mounting disk image...")
        
        let mountPoint = try await mountDMG(at: url)
        defer {
            Task { @MainActor in
                try? await unmountDMG(at: mountPoint)
            }
        }
        
        // Look for .pkg or .app
        if let pkgURL = try findFirstFile(withExtension: "pkg", in: mountPoint) {
            updateProgress(0.3, message: "Found installer package...")
            let tempPkgURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("pkg")
            try FileManager.default.copyItem(at: pkgURL, to: tempPkgURL)
            try await handlePKGFile(at: tempPkgURL)
        } else if let appURL = try findFirstFile(withExtension: "app", in: mountPoint) {
            let appName = appURL.lastPathComponent
            self.appName = appName
            
            updateProgress(0.4, message: "Preparing to copy \(appName)...")
            
            let destinationURL = URL(fileURLWithPath: "/Applications").appendingPathComponent(appName)
            
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                updateProgress(0.45, message: "Replacing existing version...")
                terminateApp(named: appName)
                try? FileManager.default.trashItem(at: destinationURL, resultingItemURL: nil)
            }
            
            try await copyItemWithProgress(from: appURL, to: destinationURL)
            
            updateProgress(0.9, message: "Cleaning up...")
            removeExtendedAttributes(at: destinationURL)
        } else {
            throw NSError(domain: "QuickDMG", code: 1, userInfo: [NSLocalizedDescriptionKey: "No installable content found in DMG"])
        }
    }

    private func handlePKGFile(at url: URL) async throws {
        updateProgress(0.5, message: "Opening installer...")
        
        return try await withCheckedThrowingContinuation { continuation in
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            
            NSWorkspace.shared.open(url, configuration: configuration) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func mountDMG(at url: URL) async throws -> URL {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        process.arguments = ["attach", url.path, "-plist", "-nobrowse", "-noverify"]
        
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        if let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
           let systemEntities = plist["system-entities"] as? [[String: Any]] {
            for entity in systemEntities {
                if let mountPoint = entity["mount-point"] as? String {
                    return URL(fileURLWithPath: mountPoint)
                }
            }
        }
        
        throw NSError(domain: "QuickDMG", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to mount DMG or retrieve mount point"])
    }

    private func unmountDMG(at mountPoint: URL) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        process.arguments = ["detach", mountPoint.path, "-force"]
        try process.run()
        process.waitUntilExit()
    }

    private func copyItemWithProgress(from source: URL, to destination: URL) async throws {
        let fileManager = FileManager.default
        
        // Get total size
        let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey, .fileSizeKey]
        let enumerator = fileManager.enumerator(at: source, includingPropertiesForKeys: Array(resourceKeys))!
        
        var totalSize: Int64 = 0
        var filesToCopy: [(URL, URL)] = []
        
        while let fileURL = enumerator.nextObject() as? URL {
            let resourceValues = try fileURL.resourceValues(forKeys: resourceKeys)
            if resourceValues.isRegularFile == true {
                totalSize += Int64(resourceValues.fileSize ?? 0)
                let relativePath = fileURL.path.replacingOccurrences(of: source.path, with: "")
                let destFileURL = destination.appendingPathComponent(relativePath)
                filesToCopy.append((fileURL, destFileURL))
            } else {
                let relativePath = fileURL.path.replacingOccurrences(of: source.path, with: "")
                let destDirURL = destination.appendingPathComponent(relativePath)
                try fileManager.createDirectory(at: destDirURL, withIntermediateDirectories: true)
            }
        }
        
        if filesToCopy.isEmpty {
            let resourceValues = try source.resourceValues(forKeys: resourceKeys)
            if resourceValues.isRegularFile == true {
                totalSize = Int64(resourceValues.fileSize ?? 0)
                filesToCopy.append((source, destination))
            } else {
                try fileManager.copyItem(at: source, to: destination)
                return
            }
        }

        var copiedSize: Int64 = 0
        let startProgress = 0.5
        let endProgress = 0.9
        
        for (src, dest) in filesToCopy {
            try fileManager.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
            try fileManager.copyItem(at: src, to: dest)
            
            let fileSize = Int64(try src.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0)
            copiedSize += fileSize
            
            let currentProgress = startProgress + (Double(copiedSize) / Double(totalSize)) * (endProgress - startProgress)
            updateProgress(currentProgress, message: "Copying \(src.lastPathComponent)...")
        }
    }

    private func terminateApp(named appName: String) {
        let runningApps = NSWorkspace.shared.runningApplications
        let nameWithoutExtension = (appName as NSString).deletingPathExtension
        
        for app in runningApps {
            if app.localizedName == nameWithoutExtension || app.bundleIdentifier?.contains(nameWithoutExtension) == true {
                app.terminate()
            }
        }
    }

    private func removeExtendedAttributes(at url: URL) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        process.arguments = ["-c", "-x", url.path]
        try? process.run()
        process.waitUntilExit()
    }

    private func findFirstFile(withExtension ext: String, in directory: URL) throws -> URL? {
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        for url in contents {
            if url.pathExtension.lowercased() == ext.lowercased() {
                return url
            }
        }
        return nil
    }
}
