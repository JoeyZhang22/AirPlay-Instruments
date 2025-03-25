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

    private var frameReceiver = FrameReceiver()
    private var pythonServer = PythonServer()
    private let host = "localhost"
    private let port = 60003
    private let delayInSeconds: Double = 2.0
    private var isClientStarted = false

    private var buttonStack: NSStackView!  // Add this line to make buttonStack accessible
    
    private var imageView: NSImageView!
    private var statusLabel: NSTextField!
    private var backButton: NSButton!
    private var startLogicProButton: NSButton!
    private var recordButton: NSButton!
    private var stopButton: NSButton!
    private var playButton: NSButton!

    // containers for top and buttom views
    private var topContainerView: NSView!
    private var middleContainerView: NSView!  // New container for image view
    private var bottomContainerView: NSView!
    
    // Define colors matching your theme
    private let navyBlue = NSColor(red: 69/255.0, green: 90/255.0, blue: 100/255.0, alpha: 1.0)
    private let lightBlue = NSColor(red: 63/255.0, green: 82/255.0, blue: 119/255.0, alpha: 1.0)
    private let steelblue = NSColor(red: 70/255.0, green: 130/255.0, blue: 180/255.0, alpha: 1.0)

    override func loadView() {
        runAppleScript()
                // Define the absolute path of the Python script
        let scriptPath = "/Users/joeyzhang/Documents/git/school/AirPlay-Instruments/AirplayInst/airplayinst/PythonBackEnd/main.py"

        startServer(scriptPath: scriptPath, instrumentType: "percussion")
        
       // Create main view (already correct)
        let mainView = NSView()
        mainView.wantsLayer = true
        self.view = mainView
        mainView.autoresizingMask = [.width, .height]
        
        // Gradient setup (optimized)
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = mainView.bounds
        gradientLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        gradientLayer.colors = [navyBlue.cgColor, lightBlue.cgColor, NSColor.black.cgColor]
        mainView.layer = gradientLayer

        // Create and configure UI elements with containers
        createContainerViews(in: mainView)
        createUIElements()
        
        // Set up constraints
        setupConstraints(for: mainView)
        
        self.view = mainView

        // Client startup and frame receiver (same as before)
        Task {
            try await Task.sleep(nanoseconds: 2 * 1_000_000_000)
            startClient()
        }

        frameReceiver.$image.sink { [weak self] newImage in
            DispatchQueue.main.async {
                self?.imageView.image = newImage
                self?.statusLabel.stringValue = newImage != nil ? "Receiving frames..." : "Waiting for frames..."
            }
        }.store(in: &cancellables)
    }

    private func createContainerViews(in mainView: NSView) {
        // Top container (header)
        topContainerView = NSView()
        topContainerView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(topContainerView)
        
        // Middle container (image view)
        middleContainerView = NSView()
        middleContainerView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(middleContainerView)
        
        // Bottom container (buttons)
        bottomContainerView = NSView()
        bottomContainerView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(bottomContainerView)
    }

    private func createUIElements() {
        // Add back button and status label to top container
        backButton = createButton(title: "Back", action: #selector(goBack))
        topContainerView.addSubview(backButton)
        
        statusLabel = NSTextField(labelWithString: "Server not running")
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = NSFont.systemFont(ofSize: 24, weight: .semibold)
        statusLabel.textColor = .white
        statusLabel.alignment = .center
        topContainerView.addSubview(statusLabel)
        
        // Add image view to middle container
        imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.wantsLayer = true
        imageView.layer?.cornerRadius = 12
        imageView.layer?.masksToBounds = true
        middleContainerView.addSubview(imageView)
        
        // Add button stack to bottom container
        startLogicProButton = createButton(title: "Start Logic Pro", action: #selector(startLogicPro))
        recordButton = createButton(title: "Record", action: #selector(startRecording))
        stopButton = createButton(title: "Stop", action: #selector(stopRecording))
        playButton = createButton(title: "Play", action: #selector(startPlayback))
    
        buttonStack = NSStackView(views: [startLogicProButton, recordButton, stopButton, playButton])
        buttonStack.orientation = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.alignment = .centerY
        buttonStack.spacing = 350 // Acts as minimum, since fillEqually enforces equal widths
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        bottomContainerView.addSubview(buttonStack)
    }
    
    private func setupConstraints(for mainView: NSView) {
            NSLayoutConstraint.activate([
                // Container layout
                topContainerView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor),
                topContainerView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor),
                topContainerView.topAnchor.constraint(equalTo: mainView.safeAreaLayoutGuide.topAnchor),
                topContainerView.heightAnchor.constraint(equalToConstant: 60),
                
                // Middle container layout (same width as top container)
                middleContainerView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor),
                middleContainerView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor),
                middleContainerView.topAnchor.constraint(equalTo: topContainerView.bottomAnchor),
                middleContainerView.bottomAnchor.constraint(equalTo: bottomContainerView.topAnchor),
                
                // Bottom container layout (same width as top container)
                bottomContainerView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor),
                bottomContainerView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor),
                bottomContainerView.bottomAnchor.constraint(equalTo: mainView.safeAreaLayoutGuide.bottomAnchor),
                bottomContainerView.heightAnchor.constraint(equalToConstant: 50),
                
                // Top container contents
                backButton.leadingAnchor.constraint(equalTo: topContainerView.leadingAnchor, constant: 20),
                backButton.centerYAnchor.constraint(equalTo: topContainerView.centerYAnchor),
                backButton.widthAnchor.constraint(equalToConstant: 80),
                backButton.heightAnchor.constraint(equalToConstant: 30),
                statusLabel.centerXAnchor.constraint(equalTo: topContainerView.centerXAnchor),
                statusLabel.centerYAnchor.constraint(equalTo: topContainerView.centerYAnchor),
                statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 10),
//                
//                // Middle container contents (image view)
                imageView.leadingAnchor.constraint(equalTo: middleContainerView.leadingAnchor, constant: 10),
                imageView.trailingAnchor.constraint(equalTo: middleContainerView.trailingAnchor, constant: -10),
                imageView.topAnchor.constraint(equalTo: middleContainerView.topAnchor, constant: 10),
                imageView.bottomAnchor.constraint(equalTo: middleContainerView.bottomAnchor, constant: -10),
//
//              // Bottom container contents
//                buttonStack.leadingAnchor.constraint(equalTo: bottomContainerView.leadingAnchor, constant: 20),
//                buttonStack.trailingAnchor.constraint(equalTo: bottomContainerView.trailingAnchor, constant: -20),
//                buttonStack.centerYAnchor.constraint(equalTo: bottomContainerView.centerYAnchor),
//                buttonStack.heightAnchor.constraint(equalToConstant: 50),

            ])
        }
    
    private func createButton(title: String, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.bezelStyle = .rounded
        button.isBordered = false
        button.wantsLayer = true
        button.layer?.cornerRadius = 12
        button.layer?.backgroundColor = steelblue.cgColor
        button.contentTintColor = .white
        button.font = NSFont.systemFont(ofSize: 18, weight: .medium)
        button.widthAnchor.constraint(equalToConstant: 150).isActive = true
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
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
