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
import SQLite3
import CoreGraphics
import Combine

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
        //Signup
        let sign_up_button = NSButton(title: "Sign Up", target: self, action: #selector(goToSignUpPage))
        sign_up_button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sign_up_button)
        
        NSLayoutConstraint.activate([
            sign_up_button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sign_up_button.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 400)
        ])
        //Signup
        let sign_in_button = NSButton(title: "Sign In", target: self, action: #selector(goToSignInPage))
        sign_in_button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sign_in_button)
        
        NSLayoutConstraint.activate([
            sign_in_button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sign_in_button.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 460)
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
    
    @objc func goToSignInPage() {
        let nextViewController = SignInViewController()
        self.view.window?.contentViewController = nextViewController
    }
    @objc func goToSignUpPage() {
            let nextViewController = SignUpViewController()
            self.view.window?.contentViewController = nextViewController
    }
    
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class SignUpViewController: NSViewController {
    var db: OpaquePointer?
    let usernameField = NSTextField()
    let passwordField = NSSecureTextField()
    
    override func loadView() {
        view = NSView(frame: NSMakeRect(0, 0, 400, 300))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        
        setupDatabase()
        setupUI()
    }
    
    private func setupDatabase() {
        let fileURL = try! FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("users.sqlite")
        
        if sqlite3_open(fileURL.path, &db) == SQLITE_OK {
            let createTableQuery = """
            CREATE TABLE IF NOT EXISTS Users (
                Id INTEGER PRIMARY KEY AUTOINCREMENT,
                Username TEXT UNIQUE,
                Password TEXT
            );
            """
            sqlite3_exec(db, createTableQuery, nil, nil, nil)
        }
    }
    
    private func setupUI() {
        let image = NSImage(named: "logo")
        if image == nil {
            print("Error: Image not found!")
            return
        }

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
        
        usernameField.placeholderString = "Username"
        passwordField.placeholderString = "Password"
        
        usernameField.translatesAutoresizingMaskIntoConstraints = false
        passwordField.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(usernameField)
        view.addSubview(passwordField)
        
        let signInButton = NSButton(title: "Sign Up", target: self, action: #selector(handleSignIn))
        signInButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(signInButton)
        
        NSLayoutConstraint.activate([
            
            usernameField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            usernameField.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 400),
            usernameField.widthAnchor.constraint(equalToConstant: 200),
            
            passwordField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            passwordField.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 430),
            passwordField.widthAnchor.constraint(equalToConstant: 200),
            
            signInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signInButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 460)
        ])
        let backButton = NSButton(title: "Back", target: self, action: #selector(goBack))
        backButton.frame = NSRect(x: 50, y: 500, width: 150, height: 600)
        backButton.bezelStyle = .rounded
        view.addSubview(backButton)
    }
    @objc func goToNextPage() {
        let nextViewController = NextViewController()
        self.view.window?.contentViewController = nextViewController
    }
    @objc private func goBack() {
        guard let window = self.view.window else {
            print("No window found")
            return
        }
        let backController = StartViewController()
        window.contentViewController = backController
    }

    
    @objc private func handleSignIn() {
        let username = usernameField.stringValue
        let password = passwordField.stringValue
        
        guard !username.isEmpty, !password.isEmpty else {
            print("Username or password cannot be empty.")
            return
        }
        
        var statement: OpaquePointer?
        let insertQuery = "INSERT INTO Users (Username, Password) VALUES (?, ?);"
        
        if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, username, -1, nil)
            sqlite3_bind_text(statement, 2, password, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("User registered successfully.")
                sqlite3_finalize(statement)
                goToNextPage()
            } else {
                print("Failed to register user.")
                sqlite3_finalize(statement)
            }
        }
        
        
    }
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class SignInViewController: NSViewController {
    var db: OpaquePointer?
    let usernameField = NSTextField()
    let passwordField = NSSecureTextField()
    
    override func loadView() {
        view = NSView(frame: NSMakeRect(0, 0, 400, 300))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        
        setupUI()
        setupDatabase()
    }
    
    private func setupDatabase() {
        let fileURL = try! FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("users.sqlite")
        
        if sqlite3_open(fileURL.path, &db) == SQLITE_OK {
            let createTableQuery = """
            CREATE TABLE IF NOT EXISTS Users (
                Id INTEGER PRIMARY KEY AUTOINCREMENT,
                Username TEXT UNIQUE,
                Password TEXT
            );
            """
            sqlite3_exec(db, createTableQuery, nil, nil, nil)
        }
    }
    
    private func setupUI() {
        let image = NSImage(named: "logo")
        if image == nil {
            print("Error: Image not found!")
            return
        }

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
        
        usernameField.placeholderString = "Username"
        passwordField.placeholderString = "Password"
        
        usernameField.translatesAutoresizingMaskIntoConstraints = false
        passwordField.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(usernameField)
        view.addSubview(passwordField)
        
        let signInButton = NSButton(title: "Sign In", target: self, action: #selector(handleSignIn))
        signInButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(signInButton)
        
        NSLayoutConstraint.activate([
            usernameField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            usernameField.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 400),
            usernameField.widthAnchor.constraint(equalToConstant: 200),
            
            passwordField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            passwordField.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 430),
            passwordField.widthAnchor.constraint(equalToConstant: 200),
            
            signInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signInButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 460)
        ])
        let backButton = NSButton(title: "Back", target: self, action: #selector(goBack))
        backButton.frame = NSRect(x: 20, y: 900, width: 100, height: 40)
        backButton.bezelStyle = .rounded
        view.addSubview(backButton)
}
    
    @objc func goToNextPage() {
        let nextViewController = NextViewController()
        self.view.window?.contentViewController = nextViewController
    }
    @objc private func goBack() {
        guard let window = self.view.window else {
            print("No window found")
            return
        }
        let backController = StartViewController()
        window.contentViewController = backController
    }

    
    @objc private func handleSignIn() {
        let username = usernameField.stringValue
        let password = passwordField.stringValue
        
        guard !username.isEmpty, !password.isEmpty else {
            print("Username or password cannot be empty.")
            return
        }
        
        
        var statement: OpaquePointer?
        let query = "SELECT * FROM Users WHERE Username = ? AND Password = ?;"
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, username, -1, nil)
            sqlite3_bind_text(statement, 2, password, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_ROW {
                print("Login successful.")
                sqlite3_finalize(statement)
                goToNextPage()
                
            } else {
                print("Invalid username or password.")
                sqlite3_finalize(statement)
            }
        }

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
        let runController = GestViewController_chords()
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

 
//CHORDS GEST MAP
class GestViewController_chords: NSViewController {
    var gestures = ["Open Palm", "Closed Fist", "Thumbs Up", "Thumbs Down", "Pointing Up", "Victory", "I Love You"]
    var chords = ["C", "C#", "Db", "D", "D#", "Eb", "E", "F", "F#", "Gb", "G", "G#", "Ab", "A", "A#", "Bb", "B"]
    var sections = ["Top", "Middle", "Bottom"]
    var chord_types = ["Major", "Minor", "Minor7", "Major7", "Dominant7", "Diminished7", "Hitchcock", "Augmented", "Augmented7#5", "AugmentedM7#", "Augmentedm7+", "Augmented7+", "Suspended4", "Suspended2", "Suspended47", "Suspended11", "Suspended4b9", "Suspendedb9", "Six", "Minor6", "Major6", "SevenSix", "SixNine", "Nine", "Major9", "Dominant7b9", "Dominant7#9", "Eleven", "Dominant7#11", "Minor11", "Thirteen", "Major13", "Minor13", "Dominant7b5", "NC", "Hendrix", "Power"]
    
    var gesture_mappings: [String: String] = [:] // Gesture-to-chord mappings
    var section_mappings: [String: String] = [:] // Section-to-chord-type mappings
    var inputFields: [String: NSTextField] = [:] // Stores text fields for gestures
    var sectionFields: [String: NSTextField] = [:] // Stores text fields for sections

    override func loadView() {
        view = NSView(frame: NSMakeRect(0, 0, 600, 400))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
        
        // Title label
        let titleLabel = NSTextField(labelWithString: "Chord Instrument Mapping")
        titleLabel.font = NSFont(name: "Helvetica Neue", size: 30)
        titleLabel.textColor = NSColor.darkGray
        titleLabel.alignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Gesture input list
        let gesturesList = createGestureInputView(title: "Gestures", items: gestures)
        gesturesList.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gesturesList)

        // Display available chords
        let chordsList = createChordsDisplayView(title: "Chords", items: chords)
        chordsList.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chordsList)
        
        // Section input list
        let sectionsList = createSectionInputView(title: "Chord Types", items: sections)
        sectionsList.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sectionsList)
        
        // Display available chord types as a reference
        let chordTypesList = createChordsDisplayGrid(title: "Chord Type List", items: chord_types)
        chordTypesList.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chordTypesList)

        // Done Button - leads to the next page
        let doneButton = NSButton(title: "Done", target: self, action: #selector(goToNextPage))
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.font = NSFont.systemFont(ofSize: 20)
        doneButton.setFrameSize(NSSize(width: 120, height: 50))
        view.addSubview(doneButton)
        
        let defaultButton = NSButton(title: "Default Mapping", target: self, action: #selector(setDefaultMapping))
        defaultButton.translatesAutoresizingMaskIntoConstraints = false
        defaultButton.font = NSFont.systemFont(ofSize: 20)
        defaultButton.setFrameSize(NSSize(width: 120, height: 50))
        view.addSubview(defaultButton)
        
        // Page layout
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 40),
            
            gesturesList.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            gesturesList.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 50),
            gesturesList.widthAnchor.constraint(equalToConstant: 250),
            
            chordsList.leadingAnchor.constraint(equalTo: gesturesList.trailingAnchor, constant: 40),
            chordsList.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 50),
            chordsList.widthAnchor.constraint(equalToConstant: 150),

            sectionsList.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -100),
            sectionsList.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 50),
            sectionsList.widthAnchor.constraint(equalToConstant: 250),

            chordTypesList.leadingAnchor.constraint(equalTo: sectionsList.trailingAnchor, constant: 40),
            chordTypesList.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 50),
            chordTypesList.widthAnchor.constraint(equalToConstant: 500),
            
            doneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            doneButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
            
            defaultButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            defaultButton.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -20)
        ])
    }

    // Create gesture input list
    private func createGestureInputView(title: String, items: [String]) -> NSStackView {
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 15

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont(name: "Helvetica Neue", size: 22)
        titleLabel.textColor = NSColor.darkGray
        stackView.addArrangedSubview(titleLabel)

        for item in items {
            let inputView = InputView(labelText: item, placeholder: "Enter chord")
            stackView.addArrangedSubview(inputView)
            inputFields[item] = inputView.textField
        }
        return stackView
    }

    // Formatting for section input list
    private func createSectionInputView(title: String, items: [String]) -> NSStackView {
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 10

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont(name: "Helvetica Neue", size: 22)
        titleLabel.textColor = NSColor.darkGray
        stackView.addArrangedSubview(titleLabel)

        for item in items {
            let inputView = InputView(labelText: item, placeholder: "Enter chord type")
            stackView.addArrangedSubview(inputView)
            sectionFields[item] = inputView.textField
        }
        return stackView
    }

    // Formatting for available chords
    private func createChordsDisplayView(title: String, items: [String]) -> NSStackView {
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 15

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont(name: "Helvetica Neue", size: 22)
        titleLabel.textColor = NSColor.darkGray
        stackView.addArrangedSubview(titleLabel)

        for item in items {
            let label = NSTextField(labelWithString: item)
            label.font = NSFont(name: "Helvetica Neue", size: 18)
            stackView.addArrangedSubview(label)
        }
        return stackView
    }
    
    // Formatting for available chord types
    private func createChordsDisplayGrid(title: String, items: [String]) -> NSStackView {
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 15

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont(name: "Helvetica Neue", size: 22)
        titleLabel.textColor = NSColor.darkGray
        stackView.addArrangedSubview(titleLabel)

        let gridView = NSGridView()
        gridView.columnSpacing = 20
        gridView.rowSpacing = 20
        let columns = 3
        
        var currentRow: [NSTextField] = []
        for (index, item) in items.enumerated() {
            let label = NSTextField(labelWithString: item)
            label.font = NSFont(name: "Helvetica Neue", size: 18)
            label.translatesAutoresizingMaskIntoConstraints = false
            currentRow.append(label)
            
            if currentRow.count == columns || index == items.count - 1 {
                gridView.addRow(with: currentRow)
                currentRow.removeAll()
            }
        }
        stackView.addArrangedSubview(gridView)
        return stackView
    }

    // Go to next page
    @objc func goToNextPage() {
        saveMappingsToJSON()  // Save mappings before transition
        let runconc = RunController_chords()
        self.view.window?.contentViewController = runconc
    }
    
    // Set default mappings and go to next page
    @objc private func setDefaultMapping() {
        gesture_mappings = [
            "Open Palm": "C",
            "Closed Fist": "D",
            "Thumbs Down": "E",
            "Thumbs Up": "F",
            "Pointing Up": "G",
            "Victory": "A",
            "I Love You": "B"
        ]
        section_mappings = [
            "Top": "Major",
            "Middle": "Minor",
            "Bottom": "Dominant7"
        ]
        for (gesture, textField) in inputFields {
            textField.stringValue = gesture_mappings[gesture] ?? ""
        }
        for (section, textField) in sectionFields {
            textField.stringValue = section_mappings[section] ?? ""
        }
        goToNextPage()
    }

    // Save mappings to a JSON file
    private func saveMappingsToJSON() {
        var invalidEntries: [String] = []
        var firstInvalidField: NSTextField? = nil

        // Validate gestures to chords
        for (gesture, textField) in inputFields {
            let userInput = textField.stringValue
            if !chords.contains(userInput) && !userInput.isEmpty {
                invalidEntries.append("\(gesture): \(userInput)")
                if firstInvalidField == nil { firstInvalidField = textField }
            } else {
                gesture_mappings[gesture] = userInput.isEmpty ? "None" : userInput
            }
        }

        // Validate sections to chord types
        for (section, textField) in sectionFields {
            let userInput = textField.stringValue
            if !chord_types.contains(userInput) && !userInput.isEmpty {
                invalidEntries.append("\(section): \(userInput)")
                if firstInvalidField == nil { firstInvalidField = textField }
            } else {
                section_mappings[section] = userInput.isEmpty ? "None" : userInput
            }
        }

        if !invalidEntries.isEmpty {
            showAlert(message: "Invalid Entries", info: "The following inputs are invalid:\n\(invalidEntries.joined(separator: "\n"))") {
                firstInvalidField?.becomeFirstResponder() // Refocus on the first invalid field
            }
            return
        }

        let jsonFilePath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("gesture_mappings.json")
        
        let data: [String: Any] = [
            "gesture_to_chord": gesture_mappings,
            "chord_types": section_mappings
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            try jsonData.write(to: jsonFilePath)
            print("Mappings saved successfully to \(jsonFilePath)")
        } catch {
            print("Error saving JSON: \(error.localizedDescription)")
        }
    }

    // Function to show an alert for invalid inputs with a completion handler
    private func showAlert(message: String, info: String, completion: (() -> Void)? = nil) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = info
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal() // Wait for user to click OK
        completion?() // Execute completion function after user clicks "OK"
    }
}

// Handles Text Input for Chord & Chord Type Entry
class InputView: NSView {
    let textField = NSTextField()

    init(labelText: String, placeholder: String) {
        super.init(frame: .zero)
        
        let label = NSTextField(labelWithString: "\(labelText):")
        label.font = NSFont(name: "Helvetica Neue", size: 18)
        label.textColor = .black
        
        textField.placeholderString = placeholder
        textField.font = NSFont(name: "Helvetica Neue", size: 18)
        textField.isBordered = true
        textField.drawsBackground = true
        textField.backgroundColor = .white
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.spacing = 10
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(textField)
        
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

////////////////////////////////////////////////////////////////////////????/////
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
        startServer()
        
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
        Thread.sleep(forTimeInterval: 0.5)

        // Simulate pressing Enter
        let keyEnter: CGKeyCode = 36 // Key code for Enter
        let enterDownEvent = CGEvent(keyboardEventSource: source, virtualKey: keyEnter, keyDown: true)
        enterDownEvent?.post(tap: .cghidEventTap)

        let enterUpEvent = CGEvent(keyboardEventSource: source, virtualKey: keyEnter, keyDown: false)
        enterUpEvent?.post(tap: .cghidEventTap)
    }
    private var cancellables = Set<AnyCancellable>()
    @objc private func startServer() {
        pythonServer.start()
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





