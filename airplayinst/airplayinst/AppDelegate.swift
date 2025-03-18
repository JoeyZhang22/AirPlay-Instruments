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
        for existingWindow in NSApplication.shared.windows {
            existingWindow.close()
        }

        // Create the main window
        window = NSWindow(contentRect: NSMakeRect(0, 0, 400, 300),
                          styleMask: [.titled, .closable, .resizable],
                          backing: .buffered, defer: false)
        window?.center()
        window?.title = "Airplay Instruments"
        window?.makeKeyAndOrderFront(nil)

        // Set the initial view controller
        let startViewController = StartViewController()
        window?.contentViewController = startViewController
    }
}

