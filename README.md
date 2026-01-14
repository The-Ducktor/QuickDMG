# QuickDMG

QuickDMG is a streamlined macOS utility designed to simplify the installation of applications from disk images (`.dmg`) and installer packages (`.pkg`). It automates the tedious steps of mounting, copying, and cleaning up, providing a "one-click" style experience for manual app installs.

## Features

-   **Automated DMG Handling**: Automatically mounts disk images, locates the application or package within, and unmounts the image when finished.
-   **Smart Installation**: Detects existing versions of an application in `/Applications`, terminates them if they are running, and replaces them cleanly.
-   **Integrity Verification**: Calculates and compares SHA256 hashes of the source and destination files to ensure a bit-perfect copy.
-   **Quarantine Removal**: Automatically strips extended attributes (like the `com.apple.quarantine` flag) so you can launch your new apps immediately.
-   **PKG Support**: Detects and launches `.pkg` installers directly.
-   **Minimal UI**: A simple progress bar keeps you informed without cluttering your workspace.

## How It Works

1.  **Open a File**: Drag a `.dmg` or `.pkg` onto QuickDMG, or select one via the file picker.
2.  **Processing**: The app mounts the image and scans for installable content.
3.  **Installation**: 
    -   If an `.app` is found, it is copied to `/Applications`.
    -   If a `.pkg` is found, the system installer is launched.
4.  **Completion**: Once the process is finished, the DMG is unmounted and QuickDMG automatically closes.

## Requirements

-   macOS 14.0 or later
-   Swift 6.0+

