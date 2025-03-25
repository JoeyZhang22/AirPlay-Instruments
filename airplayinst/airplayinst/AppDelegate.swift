//
//  AppDelegate.swift
//  airplayinst
//
//  Created by Logan Clarke on 2025-01-10.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Close any automatically created window
        NSApplication.shared.windows.forEach { $0.close() }

        // Get screen dimensions
        let screenSize = NSScreen.main?.frame.size ?? CGSize(width: 1200, height: 800)
        
        // Create the main window with proper configuration
        window = NSWindow(
            contentRect: NSRect(origin: .zero, size: screenSize),
            styleMask: [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // Configure window for edge-to-edge content
        window?.titlebarAppearsTransparent = true
        window?.titleVisibility = .hidden
        window?.isOpaque = false
        window?.backgroundColor = .clear
        window?.center()
        window?.title = "Airplay Instruments"
        
        // Set the initial view controller
        let startViewController = StartViewController()
        window?.contentViewController = startViewController
        window?.makeKeyAndOrderFront(nil)
        
        // Ensure content fills the window
        window?.contentView?.wantsLayer = true
        window?.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
    }
}

