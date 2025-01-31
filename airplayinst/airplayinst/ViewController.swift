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
import AVFoundation
import AppKit
import Foundation
import CoreMIDI

/*
firstpage:
 1. Logo
 2. Name
 3. Sign in <button>
 4. Play as guest <button>
 */


class MIDISender {
    private var midiClient: MIDIClientRef = 0
    private var midiOutPort: MIDIPortRef = 0

    init() {
        MIDIClientCreate("MIDI Client" as CFString, nil, nil, &midiClient)
        MIDIOutputPortCreate(midiClient, "MIDI Output" as CFString, &midiOutPort)
    }

    func sendMMCCommand(command: UInt8) {
        var packet = MIDIPacket()
        var packetList = MIDIPacketList(numPackets: 1, packet: packet)
        var timeStamp: UInt64 = 0

        // MMC Command Structure
        let mmcMessage: [UInt8] = [0xF0, 0x7F, 0x7F, 0x06, command, 0xF7] // SysEx Format

        MIDIPacketListInit(&packetList)
        MIDIPacketListAdd(&packetList, 1024, &packet, timeStamp, mmcMessage.count, mmcMessage)

        // Send MIDI message to all available destinations
        let destinations = MIDIGetNumberOfDestinations()
        for i in 0..<destinations {
            let destination = MIDIGetDestination(i)
            var name: Unmanaged<CFString>?
            MIDIObjectGetStringProperty(destination, kMIDIPropertyName, &name)

            if let name = name?.takeRetainedValue() as String?, name == "Logic Pro Virtual Input" {
                MIDISend(midiOutPort, destination, &packetList)
                print("Sent MMC command to \(name)")
            }
        }
        
    }

    func startRecording() {
        sendMMCCommand(command: 0x06) // Record Start
        print("Sent Record Start")
    }

    func stopRecording() {
        sendMMCCommand(command: 0x01) // Stop
        print("Sent Stop")
    }
}


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
        let sign_in_button = NSButton(title: "Sign In", target: self, action: #selector(goToNextPage))
        sign_in_button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sign_in_button)
        
        NSLayoutConstraint.activate([
            sign_in_button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sign_in_button.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 400)
        ])
        let guest_button = NSButton(title: "Play As Guest", target: self, action: #selector(goToNextPage))
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

    @objc func goToNextPage() {
        let nextViewController = NextViewController()
        self.view.window?.contentViewController = nextViewController
    }
}



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
class RunController_chords: NSViewController {
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
        let logicButton_metro = NSButton(title: "Metronome", target: self, action: #selector(stopRecording))
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
            menu.addItem(withTitle: "Keyboard", action: #selector(startRecording), keyEquivalent: "c")
            menu.addItem(withTitle: "Guitar", action: #selector(startRecording), keyEquivalent: "d")
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
        let midiSender = MIDISender()
        midiSender.startRecording()
        //midiSender.stopRecording()
    }
    @objc private func stopRecording() {
        let midiSender = MIDISender()
        midiSender.stopRecording()
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
        let logicButton_metro = NSButton(title: "Metronome", target: self, action: #selector(stopRecording))
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
        let midiSender = MIDISender()
        midiSender.startRecording()
        //midiSender.stopRecording()
    }
    @objc private func stopRecording() {
        let midiSender = MIDISender()
        midiSender.stopRecording()
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
        let logicButton_metro = NSButton(title: "Metronome", target: self, action: #selector(stopRecording))
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
            menu.addItem(withTitle: "Keyboard", action: #selector(startRecording), keyEquivalent: "c")
            menu.addItem(withTitle: "Guitar", action: #selector(startRecording), keyEquivalent: "d")
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
        let midiSender = MIDISender()
        midiSender.startRecording()
        //midiSender.stopRecording()
    }
    @objc private func stopRecording() {
        let midiSender = MIDISender()
        midiSender.stopRecording()
    }
}





