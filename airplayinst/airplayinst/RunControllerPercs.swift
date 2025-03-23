import Cocoa
import AVFoundation
import AppKit
import Foundation
import CoreMIDI
import SQLite3
import CoreGraphics
import Combine
import SwiftUI

class RunController_percs: NSViewController {
    private var frameReceiver = FrameReceiver() // ObservableObject for receiving frames
    private var pythonServer = PythonServer()   // ObservableObject for starting the server

    private let host = "localhost" // Replace with your server's host
    private let port = 60003       // Replace with your server's port
    private let delayInSeconds: Double = 2.0 // Delay duration before starting the client

    private var isClientStarted = false // To track if the client has started

    private var imageView: NSImageView!
    private var statusLabel: NSTextField!
    private var startServerButton: NSButton!
    private var stopServerButton: NSButton!
    private var startClientButton: NSButton!
    override func loadView() {
        runAppleScript()
                // Define the absolute path of the Python script
        let scriptPath = "/Users/joeyzhang/Documents/git/school/AirPlay-Instruments/AirplayInst/airplayinst/PythonBackEnd/main.py"

        startServer(scriptPath: scriptPath, instrumentType: "percussion")
        
        let mainView = NSView()
        mainView.wantsLayer = true
        mainView.layer?.backgroundColor = NSColor.black.cgColor
        
        // Initialize and configure imageView
        imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageScaling = .scaleProportionallyUpOrDown
        mainView.addSubview(imageView, positioned: .below, relativeTo: nil) // Ensure it's at the back
        
        // Initialize and configure statusLabel
        statusLabel = NSTextField(labelWithString: "Server not running")
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = NSFont.systemFont(ofSize: 24)
        statusLabel.textColor = .gray
        mainView.addSubview(statusLabel)
        
        // Add buttons using frames or constraints
        let logicButton_rec = NSButton(title: "Start Recording", target: self, action: #selector(startRecording))
        logicButton_rec.frame = NSRect(x: 20, y: 60, width: 120, height: 40)
        logicButton_rec.bezelStyle = .rounded
        mainView.addSubview(logicButton_rec)
        
        let logicButton_stop_rec = NSButton(title: "Stop Recording", target: self, action: #selector(stopRecording))
        logicButton_stop_rec.frame = NSRect(x: 20, y: 20, width: 120, height: 40)
        logicButton_stop_rec.bezelStyle = .rounded
        mainView.addSubview(logicButton_stop_rec)
        
        let logicButton_metro = NSButton(title: "Playback", target: self, action: #selector(startRecording))
        logicButton_metro.frame = NSRect(x: 20, y: 300, width: 120, height: 40)
        logicButton_metro.bezelStyle = .rounded
        mainView.addSubview(logicButton_metro)
        
        let backButton = NSButton(title: "Back", target: self, action: #selector(goBack))
        backButton.frame = NSRect(x: 20, y: 900, width: 120, height: 40)
        backButton.bezelStyle = .rounded
        mainView.addSubview(backButton)
        
        let instDropdown = NSPopUpButton(frame: NSRect(x: 20, y: 500, width: 120, height: 40))
        let menu = NSMenu()
        menu.addItem(withTitle: "Keyboard", action: #selector(startRecording), keyEquivalent: "c")
        menu.addItem(withTitle: "Acoustic Guitar", action: #selector(startRecording), keyEquivalent: "d")
        menu.addItem(withTitle: "Electric Guitar", action: #selector(startRecording), keyEquivalent: "e")
        instDropdown.menu = menu
        mainView.addSubview(instDropdown)
        
        // Activate constraints for imageView and statusLabel
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: mainView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor),
            
            statusLabel.centerXAnchor.constraint(equalTo: mainView.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: mainView.centerYAnchor)
        ])
        
        Task {
            try await Task.sleep(nanoseconds: 2 * 1_000_000_000) // 2 seconds in nanoseconds
            startClient()
            print("After 2 seconds")
        }
       
        
        frameReceiver.$image.sink { [weak self] newImage in
            DispatchQueue.main.async {
                self?.imageView.image = newImage
                self?.statusLabel.stringValue = newImage != nil ? "Receiving frames..." : "Waiting for frames..."
            }
        }.store(in: &cancellables)
        
        self.view = mainView
    }

    @objc private func goBack() {
        stopServer()
        guard let window = self.view.window else {
            print("No window found")
            return
        }
        let nextViewController = NextViewController()
        window.contentViewController = nextViewController
    }
        @objc private func startLogicPro() {
            let appPath = "/Applications/Logic Pro.app"
            let workspace = NSWorkspace.shared

            if workspace.open(URL(fileURLWithPath: appPath)) {
                print("Logic Pro started successfully!")
            } else {
                print("Failed to start Logic Pro.")
            }
        }
    @objc private func startRecording() {
        // Usage
        let midiSender = MIDISender()
        midiSender.sendMMCRecordStart()
    }
    @objc private func stopRecording() {
        
        let midiSender = MIDISender()
        midiSender.sendMMCRecordStop()
    }
    @objc private func startPlayback() {
        
        let midiSender = MIDISender()
        midiSender.sendMMCPlay()
    }
    func runAppleScript() {
        let script = """
        tell application "Logic Pro"
            activate
            delay 1 -- Wait for Logic Pro to come to the foreground
        end tell

        tell application "System Events"
            keystroke "n" using {command down, shift down}
            delay 0.5 -- Wait for the new project dialog to appear
            keystroke return -- Press Enter
        end tell
        """

        if let appleScript = NSAppleScript(source: script) {
            var errorDict: NSDictionary? = nil
            appleScript.executeAndReturnError(&errorDict)
            if let error = errorDict {
                print("Error running AppleScript: \(error)")
            }
        }
    }
    func simulateKeyPress() {
        // Create a new keyboard event for Shift + Command + N
        let source = CGEventSource(stateID: .hidSystemState)
        let keyN: CGKeyCode = 45 // Key code for 'N'
        let shiftCommandFlags: CGEventFlags = [.maskShift, .maskCommand]

        // Simulate Shift + Command + N
        let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: keyN, keyDown: true)
        keyDownEvent?.flags = shiftCommandFlags
        keyDownEvent?.post(tap: .cghidEventTap)

        let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: keyN, keyDown: false)
        keyUpEvent?.flags = shiftCommandFlags
        keyUpEvent?.post(tap: .cghidEventTap)

        // Wait for a short delay (optional)
        Thread.sleep(forTimeInterval: 0.2)

        // Simulate pressing Enter
        let keyEnter: CGKeyCode = 36 // Key code for Enter
        let enterDownEvent = CGEvent(keyboardEventSource: source, virtualKey: keyEnter, keyDown: true)
        enterDownEvent?.post(tap: .cghidEventTap)

        let enterUpEvent = CGEvent(keyboardEventSource: source, virtualKey: keyEnter, keyDown: false)
        enterUpEvent?.post(tap: .cghidEventTap)
    }
    private var cancellables = Set<AnyCancellable>()
    @objc private func startServer(scriptPath: String, instrumentType: String) {
        pythonServer.start(scriptPath: scriptPath, instrumentType: instrumentType)
        //updateUI()
    }
    
    @objc private func stopServer() {
        pythonServer.stop()
        frameReceiver.stop()
        isClientStarted = false
        //updateUI()
    }
    
    @objc private func startClient() {
        DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) {
            self.frameReceiver.start(host: self.host, port: self.port)
            self.isClientStarted = true
            //self.updateUI()
        }
        
    }
    private func updateUI() {
        //startServerButton.isEnabled = !pythonServer.isRunning
        //stopServerButton.isEnabled = pythonServer.isRunning
        //startClientButton.isEnabled = pythonServer.isRunning && !isClientStarted
        
        if pythonServer.isRunning {
            statusLabel.stringValue = isClientStarted ? "Receiving frames..." : "Server running"
        } else {
            statusLabel.stringValue = "Server not running"
        }
    }
}
