//
//  WindowsController.swift
//  QuickDMG
//
//  Created by Jackson Powell on 1/18/25.
//

import Cocoa
import SwiftUI
import Cocoa
import SwiftUI

class WindowController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Configure window settings (removing visual effects for now to simplify)
        window?.title = "QuickDMG"
        window?.titlebarAppearsTransparent = true // Transparent title bar
        window?.styleMask.insert(.fullSizeContentView) // Full-size content view
        window?.level = .floating
        
        // Set minimum height for window (adjust as necessary)
        window?.minSize = NSSize(width: 300, height: 100)
    }
}
