//
//  ViewController.swift
//  airplayinst
//
//  Created by Logan Clarke on 2025-01-10.
//

//
//  ViewController.swift
//  Airplay_Instruments_appkit
//
//  Created by Logan Clarke on 2025-01-02.
//

import Cocoa
import Combine
import AVFoundation
import AppKit
import Foundation
import CoreMIDI
import SQLite3
import CoreGraphics

/*
firstpage:
 1. Logo
 2. Name
 3. Sign in <button>
 4. Play as guest <button>
 */




class MIDISender {
    var midiClient = MIDIClientRef()
    var midiOutPort = MIDIPortRef()
    var logicMIDIEndpoint = MIDIEndpointRef()

    init() {
        setupMIDI()
    }

    private func setupMIDI() {
        // Create a MIDI Client
        MIDIClientCreate("MIDI Client" as CFString, nil, nil, &midiClient)
        
        // Create an Output Port
        MIDIOutputPortCreate(midiClient, "MIDI Output Port" as CFString, &midiOutPort)
        
        // Find Logic Pro’s MIDI Destination
        let numDestinations = MIDIGetNumberOfDestinations()
        for i in 0..<numDestinations {
            let endpoint = MIDIGetDestination(i)
            if endpoint != 0 {
                var name: Unmanaged<CFString>?
                if MIDIObjectGetStringProperty(endpoint, kMIDIPropertyDisplayName, &name) == noErr {
                    let endpointName = name?.takeRetainedValue() as String?
                    print("Found MIDI Destination: \(endpointName ?? "Unknown")")
                    if endpointName?.contains("Logic Pro") == true {
                        logicMIDIEndpoint = endpoint
                        print("Logic Pro MIDI endpoint found!")
                        break
                    }
                }
            }
        }
        
        if logicMIDIEndpoint == 0 {
            print("Logic Pro MIDI endpoint not found. Ensure Logic Pro is running and configured to receive MIDI.")
        }
    }

    func sendMMCPlay() {
        guard logicMIDIEndpoint != 0 else {
            print("No Logic Pro MIDI endpoint found!")
            return
        }
        
        // MIDI SysEx Message: MMC Play Command
        let mmcPlay: [UInt8] = [0xF0, 0x7F, 0x7F, 0x06, 0x02, 0xF7] // MMC Play

        // Allocate MIDI Packet List
        let packetListPointer = UnsafeMutablePointer<MIDIPacketList>.allocate(capacity: 1)
        var packetList = packetListPointer.pointee
        var packet = MIDIPacketListInit(&packetList)

        packet = MIDIPacketListAdd(&packetList, 1024, packet, 0, mmcPlay.count, mmcPlay)

        // Send MIDI to Logic Pro
        let result = MIDISend(midiOutPort, logicMIDIEndpoint, &packetList)
        if result == noErr {
            print("MMC Play command sent to Logic Pro!")
        } else {
            print("Failed to send MIDI: \(result)")
        }
    }
    func sendMMCRecordStart() {
        guard logicMIDIEndpoint != 0 else {
            print("No Logic Pro MIDI endpoint found!")
            return
        }

        // MIDI SysEx: MMC Record Start
        let mmcRecordStart: [UInt8] = [0xF0, 0x7F, 0x7F, 0x06, 0x06, 0xF7]

        // Create a MIDI Packet List
        var packetList = MIDIPacketList()
        var packet = MIDIPacketListInit(&packetList)
        packet = MIDIPacketListAdd(&packetList, 1024, packet, 0, mmcRecordStart.count, mmcRecordStart)

        // Send MIDI to Logic Pro
        let result = MIDISend(midiOutPort, logicMIDIEndpoint, &packetList)
        if result == noErr {
            print("MMC Record Start sent to Logic Pro!")
        } else {
            print("Failed to send MMC Record Start: \(result)")
        }
    }

    func sendMMCRecordStop() {
        guard logicMIDIEndpoint != 0 else {
            print("No Logic Pro MIDI endpoint found!")
            return
        }

        // MIDI SysEx: MMC Stop
        let mmcStop: [UInt8] = [0xF0, 0x7F, 0x7F, 0x06, 0x01, 0xF7]

        // Create a MIDI Packet List
        var packetList = MIDIPacketList()
        var packet = MIDIPacketListInit(&packetList)
        packet = MIDIPacketListAdd(&packetList, 1024, packet, 0, mmcStop.count, mmcStop)

        // Send MIDI to Logic Pro
        let result = MIDISend(midiOutPort, logicMIDIEndpoint, &packetList)
        if result == noErr {
            print("MMC Stop sent to Logic Pro!")
        } else {
            print("Failed to send MMC Stop: \(result)")
        }
    }
    
}

// Usage
//let midiSender = MIDISender()
//midiSender.sendMMCPlay()




class StartViewController: NSViewController {
    override func loadView() {
        view = NSView(frame: NSMakeRect(0, 0, 400, 300))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        //logo
        let image = NSImage(named: "logo")
        if image == nil {
            print("Error: Image not found!")
            return
        }
        //start button
        let sign_in_button = NSButton(title: "Sign In", target: self, action: #selector(goToLoginPage))
        sign_in_button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sign_in_button)
        
        NSLayoutConstraint.activate([
            sign_in_button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sign_in_button.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 400)
        ])
        let guest_button = NSButton(title: "Play As Guest", target: self, action: #selector(goToGuestPage))
        guest_button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(guest_button)
        
        NSLayoutConstraint.activate([
            guest_button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            guest_button.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 430)
        ])
        
        let imageView = NSImageView()
        imageView.image = image
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageScaling = .scaleProportionallyUpOrDown
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 700),
            imageView.heightAnchor.constraint(equalToConstant: 700)
        ])
    }

    @objc func goToGuestPage() {
        let nextViewController = NextViewController()
        self.view.window?.contentViewController = nextViewController
    }
    @objc func goToLoginPage() {
            let nextViewController = LoginViewController()
            self.view.window?.contentViewController = nextViewController
    }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class LoginViewController: NSViewController {
    override func loadView() {
        // create the database if not existing
        var db: OpaquePointer?
        let fileURL = try! FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("myDatabase.sqlite")

        if sqlite3_open(fileURL.path, &db) == SQLITE_OK {
            print("Successfully opened connection to database at \(fileURL.path)")
        } else {
            print("Unable to open database.")
        }
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS Users (
            Id INTEGER PRIMARY KEY AUTOINCREMENT,
            Username TEXT UNIQUE,
            Password TEXT
        );
        """
        
        if sqlite3_exec(db, createTableQuery, nil, nil, nil) == SQLITE_OK {
            print("Users table created successfully.")
        } else {
            print("Failed to create Users table.")
        }
        //////////////////////////////////////////////////////////////////
        
        view = NSView(frame: NSMakeRect(0, 0, 400, 300))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        //logo
        let image = NSImage(named: "logo")
        if image == nil {
            print("Error: Image not found!")
            return
        }
        //start button
        let sign_in_button = NSButton(title: "Sign In", target: self, action: #selector(goToLoginPage))
        sign_in_button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sign_in_button)
        
        NSLayoutConstraint.activate([
            sign_in_button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sign_in_button.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 400)
        ])
        let guest_button = NSButton(title: "Play As Guest", target: self, action: #selector(goToGuestPage))
        guest_button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(guest_button)
        
        NSLayoutConstraint.activate([
            guest_button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            guest_button.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 430)
        ])
        
        let imageView = NSImageView()
        imageView.image = image
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageScaling = .scaleProportionallyUpOrDown
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 700),
            imageView.heightAnchor.constraint(equalToConstant: 700)
        ])
    }

    @objc func goToGuestPage() {
        let nextViewController = NextViewController()
        self.view.window?.contentViewController = nextViewController
    }
    @objc func goToLoginPage() {
            let nextViewController = NextViewController()
            self.view.window?.contentViewController = nextViewController
    }
    
    
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Second Page: Next ViewController
/*
 1. Logo
 2. instrument selection title
 3. <instrument buttons>
 4. back button
 */


class NextViewController: NSViewController {
    override func loadView() {
        view = NSView(frame: NSMakeRect(0, 0, 400, 300))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        
        let percButton = NSButton(title: "Percussion", target: self, action: #selector(goToNextPage_perc))
        percButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(percButton)
        NSLayoutConstraint.activate([
            percButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -300),
            percButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -5)
        ])
        let chordButton = NSButton(title: "Chords", target: self, action: #selector(goToNextPage_chord))
        chordButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chordButton)
        NSLayoutConstraint.activate([
            chordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 300),
            chordButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -5)
        ])
        
        
        let expressButton = NSButton(title: "Expressive", target: self, action: #selector(goToNextPage_express))
        expressButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(expressButton)
        NSLayoutConstraint.activate([
            expressButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            expressButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 450)
        ])
        
        
        
        let chords_image = NSImage(named: "chords_inst")
        if chords_image == nil {
            print("Error: Image not found!")
            return
        }
        
        let chordsimageView = NSImageView()
        chordsimageView.image = chords_image
        chordsimageView.translatesAutoresizingMaskIntoConstraints = false
        chordsimageView.imageScaling = .scaleProportionallyUpOrDown
        view.addSubview(chordsimageView)
        NSLayoutConstraint.activate([
            chordsimageView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 300),
            chordsimageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -200),
            chordsimageView.widthAnchor.constraint(equalToConstant: 350),
            chordsimageView.heightAnchor.constraint(equalToConstant: 350)
        ])
        
        let perc_image = NSImage(named: "percs")
        if perc_image == nil {
            print("Error: Image not found!")
            return
        }
        
        let percimageView = NSImageView()
        percimageView.image = perc_image
        percimageView.translatesAutoresizingMaskIntoConstraints = false
        percimageView.imageScaling = .scaleProportionallyUpOrDown
        view.addSubview(percimageView)
        NSLayoutConstraint.activate([
            percimageView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -300),
            percimageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -200),
            percimageView.widthAnchor.constraint(equalToConstant: 350),
            percimageView.heightAnchor.constraint(equalToConstant: 350)
        ])
        
        
        let express_image = NSImage(named: "express_inst")
        if express_image == nil {
            print("Error: Image not found!")
            return
        }
        
        
        let expressimageView = NSImageView()
        expressimageView.image = express_image
        expressimageView.translatesAutoresizingMaskIntoConstraints = false
        expressimageView.imageScaling = .scaleProportionallyUpOrDown
        view.addSubview(expressimageView)
        NSLayoutConstraint.activate([
            expressimageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            expressimageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 250),
            expressimageView.widthAnchor.constraint(equalToConstant: 350),
            expressimageView.heightAnchor.constraint(equalToConstant: 350)
        ])
        
        
        let backButton = NSButton(title: "Back", target: self, action: #selector(goBack))
        backButton.frame = NSRect(x: 20, y: 900, width: 100, height: 40)
        backButton.bezelStyle = .rounded
        view.addSubview(backButton)
        
        
        
    }
    @objc func goToNextPage_chord() {
        let runController = RunController_chords()
        self.view.window?.contentViewController = runController
    }
    @objc func goToNextPage_perc() {
        let runController = RunController_percs()
        self.view.window?.contentViewController = runController
    }
    @objc func goToNextPage_express() {
        let runController = RunController_express()
        self.view.window?.contentViewController = runController
    }

    @objc private func goBack() {
        guard let window = self.view.window else {
            print("No window found")
            return
        }
        let backController = StartViewController()
        window.contentViewController = backController
    }
    
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(granted)
            }
        case .authorized:
            completion(true)
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
}    

 
 

/*
 View for the instrument play page
 
*/

class CamViewController: NSView {
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupCamera()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCamera()
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("No camera found")
            return
        }
        do {
             let input = try AVCaptureDeviceInput(device: camera)
             if captureSession.canAddInput(input) {
                 captureSession.addInput(input)
             } else {
                 print("Unable to add camera input")
                 return
             }
        } catch {
            print("Error accessing camera: \(error)")
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        guard let previewLayer = previewLayer else { return }
        
        //flip camera
        previewLayer.transform = CATransform3DMakeScale(-1, 1, 1)
        
        
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = bounds
        layer = CALayer()
        layer?.addSublayer(previewLayer)
        layer?.sublayers?.last?.zPosition = 1

        // Start the session
        captureSession.startRunning()
    }

    override func layout() {
        super.layout()
        previewLayer?.frame = bounds
    }
}



//THIS IS THE MAIN VIEW FOR PLAYING CHORDS INSTRUMENT
import AppKit
import Foundation

class RunController_chords: NSViewController {
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
        
        let mainView = NSView()
        mainView.wantsLayer = true
        mainView.layer?.backgroundColor = NSColor.black.cgColor
        
        // Add the image view to display frames
        imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(imageView)
        
        // Add the status label
        statusLabel = NSTextField(labelWithString: "Server not running")
        statusLabel.font = NSFont.systemFont(ofSize: 24)
        statusLabel.textColor = .gray
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(statusLabel)
        
        // Add buttons
        startServerButton = NSButton(title: "Start Server", target: self, action: #selector(startServer))
        startServerButton.bezelStyle = .rounded
        startServerButton.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(startServerButton)
        
        stopServerButton = NSButton(title: "Stop Server", target: self, action: #selector(stopServer))
        stopServerButton.bezelStyle = .rounded
        stopServerButton.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(stopServerButton)
        
        startClientButton = NSButton(title: "Start Client", target: self, action: #selector(startClient))
        startClientButton.bezelStyle = .rounded
        startClientButton.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(startClientButton)
        
        // Add constraints
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: mainView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor),
            
            statusLabel.centerXAnchor.constraint(equalTo: mainView.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: mainView.centerYAnchor),
            
            startServerButton.leadingAnchor.constraint(equalTo: mainView.leadingAnchor, constant: 20),
            startServerButton.topAnchor.constraint(equalTo: mainView.topAnchor, constant: 20),
            
            stopServerButton.leadingAnchor.constraint(equalTo: mainView.leadingAnchor, constant: 20),
            stopServerButton.topAnchor.constraint(equalTo: startServerButton.bottomAnchor, constant: 10),
            
            startClientButton.leadingAnchor.constraint(equalTo: mainView.leadingAnchor, constant: 20),
            startClientButton.topAnchor.constraint(equalTo: stopServerButton.bottomAnchor, constant: 10)
        ])
        
        // Update UI based on server and client state
        updateUI()
        
        // Observe changes to the frameReceiver's image
        frameReceiver.$image.sink { [weak self] newImage in
            DispatchQueue.main.async {
                self?.imageView.image = newImage
                self?.statusLabel.stringValue = newImage != nil ? "Receiving frames..." : "Waiting for frames..."
            }
        }.store(in: &cancellables)
        
        self.view = mainView
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    @objc private func startServer() {
        pythonServer.start()
        updateUI()
    }
    
    @objc private func stopServer() {
        pythonServer.stop()
        frameReceiver.stop()
        isClientStarted = false
        updateUI()
    }
    
    @objc private func startClient() {
        DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) {
            self.frameReceiver.start(host: self.host, port: self.port)
            self.isClientStarted = true
            self.updateUI()
        }
    }
    
    private func updateUI() {
        startServerButton.isEnabled = !pythonServer.isRunning
        stopServerButton.isEnabled = pythonServer.isRunning
        startClientButton.isEnabled = pythonServer.isRunning && !isClientStarted
        
        if pythonServer.isRunning {
            statusLabel.stringValue = isClientStarted ? "Receiving frames..." : "Server running"
        } else {
            statusLabel.stringValue = "Server not running"
        }
    }
    
    @objc private func goBack() {
        guard let window = self.view.window else {
            print("No window found")
            return
        }
        let nextViewController = NextViewController()
        window.contentViewController = nextViewController
    }
    
    @objc private func startRecording() {
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
            delay 1
        end tell

        tell application "System Events"
            keystroke "n" using {command down, shift down}
            delay 0.5
            keystroke return
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
}

//THIS IS THE VIEW FOR PLAYING THE
class RunController_percs: NSViewController {
    override func loadView() {
        let mainView = NSView()
        mainView.wantsLayer = true
        mainView.layer?.backgroundColor = NSColor.black.cgColor
        
        let cameraView = CamViewController(frame: .zero)
        cameraView.wantsLayer = true
        cameraView.layer?.borderWidth = 2
        cameraView.layer?.borderColor = NSColor.white.cgColor
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(cameraView)
        NSLayoutConstraint.activate([
            cameraView.centerXAnchor.constraint(equalTo: mainView.centerXAnchor),
            cameraView.centerYAnchor.constraint(equalTo: mainView.centerYAnchor),
            cameraView.widthAnchor.constraint(equalToConstant: 1200),
            cameraView.heightAnchor.constraint(equalToConstant: 900)
        ])
        //start/stop recording button
        let logicButton_rec = NSButton(title: "Start Recording", target: self, action: #selector(startRecording))
            logicButton_rec.frame = NSRect(x: 20, y: 60, width: 120, height: 40)
            logicButton_rec.bezelStyle = .rounded
            mainView.addSubview(logicButton_rec)
        
        let logicButton_stop_rec = NSButton(title: "Stop Recording", target: self, action: #selector(stopRecording))
            logicButton_stop_rec.frame = NSRect(x: 20, y: 20, width: 120, height: 40)
            logicButton_stop_rec.bezelStyle = .rounded
            mainView.addSubview(logicButton_stop_rec)
        //metronome button
        let logicButton_metro = NSButton(title: "Playback", target: self, action: #selector(stopRecording))
            logicButton_metro.frame = NSRect(x: 20, y: 300, width: 120, height: 40)
            logicButton_metro.bezelStyle = .rounded
            mainView.addSubview(logicButton_metro)
        // the back button
        let backButton = NSButton(title: "Back", target: self, action: #selector(goBack))
            backButton.frame = NSRect(x: 20, y: 900, width: 120, height: 40)
            backButton.bezelStyle = .rounded
            mainView.addSubview(backButton)
        //drop down for instrument selection
        let instDropdown = NSPopUpButton(frame: NSRect(x: 20, y: 500, width: 120, height: 40))
        let menu = NSMenu()
            menu.addItem(withTitle: "Smash", action: #selector(startRecording), keyEquivalent: "c")
            menu.addItem(withTitle: "Retro Rock", action: #selector(startRecording), keyEquivalent: "d")
            menu.addItem(withTitle: "Heavy", action: #selector(startRecording), keyEquivalent: "e")

        instDropdown.menu = menu

        // Add the dropdown to your view

        mainView.addSubview(instDropdown)
        
        
        
            self.view = mainView
    }


    @objc private func goBack() {
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
}

class RunController_express: NSViewController {
    override func loadView() {
        let mainView = NSView()
        mainView.wantsLayer = true
        mainView.layer?.backgroundColor = NSColor.black.cgColor
        
        let cameraView = CamViewController(frame: .zero)
        cameraView.wantsLayer = true
        cameraView.layer?.borderWidth = 2
        cameraView.layer?.borderColor = NSColor.white.cgColor
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(cameraView)
        NSLayoutConstraint.activate([
            cameraView.centerXAnchor.constraint(equalTo: mainView.centerXAnchor),
            cameraView.centerYAnchor.constraint(equalTo: mainView.centerYAnchor),
            cameraView.widthAnchor.constraint(equalToConstant: 1200),
            cameraView.heightAnchor.constraint(equalToConstant: 900)
        ])
        //start/stop recording button
        let logicButton_rec = NSButton(title: "Start Recording", target: self, action: #selector(startRecording))
            logicButton_rec.frame = NSRect(x: 20, y: 60, width: 120, height: 40)
            logicButton_rec.bezelStyle = .rounded
            mainView.addSubview(logicButton_rec)
        
        let logicButton_stop_rec = NSButton(title: "Stop Recording", target: self, action: #selector(stopRecording))
            logicButton_stop_rec.frame = NSRect(x: 20, y: 20, width: 120, height: 40)
            logicButton_stop_rec.bezelStyle = .rounded
            mainView.addSubview(logicButton_stop_rec)
        //metronome button
        let logicButton_metro = NSButton(title: "Playback", target: self, action: #selector(stopRecording))
            logicButton_metro.frame = NSRect(x: 20, y: 300, width: 120, height: 40)
            logicButton_metro.bezelStyle = .rounded
            mainView.addSubview(logicButton_metro)
        // the back button
        let backButton = NSButton(title: "Back", target: self, action: #selector(goBack))
            backButton.frame = NSRect(x: 20, y: 900, width: 120, height: 40)
            backButton.bezelStyle = .rounded
            mainView.addSubview(backButton)
        //drop down for instrument selection
        let instDropdown = NSPopUpButton(frame: NSRect(x: 20, y: 500, width: 120, height: 40))
        let menu = NSMenu()
            menu.addItem(withTitle: "Violin", action: #selector(startRecording), keyEquivalent: "c")
            menu.addItem(withTitle: "Theremin", action: #selector(startRecording), keyEquivalent: "d")
            menu.addItem(withTitle: "Harp", action: #selector(startRecording), keyEquivalent: "e")

        instDropdown.menu = menu



        // Add the dropdown to your view

        mainView.addSubview(instDropdown)
        
        
        
            self.view = mainView
      }


    @objc private func goBack() {
        guard let window = self.view.window else {
            print("No window found")
            return
        }
        let nextViewController = NextViewController()
        window.contentViewController = nextViewController
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
}





