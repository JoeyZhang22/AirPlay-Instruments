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
import SwiftUI

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
        view = NSView(frame: NSMakeRect(0, 0, 800, 600))  // Adjusted window size for macOS
        view.wantsLayer = true
        // Set a gradient background
        let navyBlue = NSColor(red: 69/255.0, green: 90/255.0, blue: 100/255.0, alpha: 1.0)
        let lightBlue = NSColor(red: 63/255.0, green: 82/255.0, blue: 119/255.0, alpha: 1.0)
        let steelblue = NSColor(red: 70/255.0, green: 130/255.0, blue: 180/255.0, alpha: 1.0)
        let midnightblue = NSColor(red: 25/255.0, green: 25/255.0, blue: 112/255.0, alpha: 1.0)
        
        // Create gradient layer
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            navyBlue.cgColor,
            lightBlue.cgColor,
            NSColor.black.cgColor
        ]
        gradientLayer.frame = view.bounds
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)  // Top-left corner
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)    // Bottom-right corner
        view.layer = gradientLayer

        // Animate gradient colors
        let colorAnimation = CABasicAnimation(keyPath: "colors")
        colorAnimation.fromValue = [
            navyBlue.cgColor,
            lightBlue.cgColor,
            NSColor.black.cgColor
        ]
        colorAnimation.toValue = [
            midnightblue.cgColor,
            steelblue.cgColor,
            NSColor.black.cgColor
        ]
        colorAnimation.duration = 1.5  // Animation duration in seconds
        colorAnimation.autoreverses = true  // Reverse the animation
        colorAnimation.repeatCount = .infinity  // Repeat indefinitely
        gradientLayer.add(colorAnimation, forKey: "colorChange")

        
        // Create logo image view
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

        // Make the logo circular
        imageView.wantsLayer = true
        imageView.layer?.cornerRadius = 300  // Half of the image size (600x600)
        imageView.layer?.masksToBounds = true

        // Add a border to the image view
        imageView.layer?.borderWidth = 10  // Initial border width

        // Adjust constraints for the image
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 80),  // Move the image to the top
            imageView.widthAnchor.constraint(equalToConstant: 600), // Adjusted image size
            imageView.heightAnchor.constraint(equalToConstant: 600) // Adjusted image size
        ])

        // Add pulse animation to the border
        addPulseAnimation(to: imageView)

        // Add scaling animation to the logo
        addScalingAnimation(to: imageView)

        // Create a stack view for buttons
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .centerX
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        // Create buttons and add them to the stack view
        let sign_up_button = createButton(title: "Sign Up", action: #selector(goToSignUpPage), backgroundColor: lightBlue)
        let sign_in_button = createButton(title: "Sign In", action: #selector(goToSignInPage), backgroundColor: lightBlue)
        let guest_button = createButton(title: "Play As Guest", action: #selector(goToGuestPage), backgroundColor: lightBlue)
        
        stackView.addArrangedSubview(sign_up_button)
        stackView.addArrangedSubview(sign_in_button)
        stackView.addArrangedSubview(guest_button)
        
        // Adjust constraints for the stack view
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 40)  // Adjusted spacing
        ])
    }
    
    // Function to add pulse animation to the border
    func addPulseAnimation(to imageView: NSImageView) {
        // Create an animation for the border width (pulse effect)
        let pulseAnimation = CABasicAnimation(keyPath: "borderWidth")
        pulseAnimation.fromValue = 10  // Initial border width
        pulseAnimation.toValue = 20    // Maximum border width during pulse
        pulseAnimation.duration = 1.5  // Duration of one pulse cycle
        pulseAnimation.autoreverses = true  // Reverse the animation
        pulseAnimation.repeatCount = .infinity  // Repeat indefinitely

        // Add the animation to the image view's layer
        imageView.layer?.add(pulseAnimation, forKey: "pulseAnimation")
    }

    // Function to add scaling animation to the logo
    func addScalingAnimation(to imageView: NSImageView) {
        // Create an animation for scaling the logo
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0  // Original size
        scaleAnimation.toValue = 1.05   // Slightly larger size
        scaleAnimation.duration = 2.0
        scaleAnimation.autoreverses = true
        scaleAnimation.repeatCount = .infinity

        // Add the scaling animation to the image view's layer
        imageView.layer?.add(scaleAnimation, forKey: "scaleAnimation")
    }

    // Helper function to create and style buttons
    func createButton(title: String, action: Selector, backgroundColor: NSColor) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.translatesAutoresizingMaskIntoConstraints = false
        styleButton(button, backgroundColor: backgroundColor)
        addHoverEffect(to: button) // Add hover effect
        return button
    }

    // Button styling
    func styleButton(_ button: NSButton, backgroundColor: NSColor = .systemBlue) {
        // Button Appearance
        button.bezelStyle = .rounded
        button.isBordered = false
        button.wantsLayer = true
        button.layer?.cornerRadius = 12  // Softer rounded corners
        button.layer?.backgroundColor = backgroundColor.cgColor
        button.contentTintColor = .white  // Text color
        
        // Font Styling
        button.font = NSFont.systemFont(ofSize: 18, weight: .medium)  // Adjusted font size
        
        // Shadow styling for a more modern feel
        button.layer?.shadowColor = NSColor.black.withAlphaComponent(0.2).cgColor
        button.layer?.shadowOpacity = 0.2
        button.layer?.shadowOffset = CGSize(width: 0, height: -2)  // Subtle upward shadow
        button.layer?.shadowRadius = 6  // Soft and blurred shadow
        
        // Set button size
        button.widthAnchor.constraint(equalToConstant: 250).isActive = true  // Adjusted button width
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true  // Adjusted button height
    }

    // Add hover effect to a button
    func addHoverEffect(to button: NSButton) {
        let hoverArea = NSTrackingArea(
            rect: button.bounds,
            options: [.mouseEnteredAndExited, .activeInActiveApp],
            owner: self,
            userInfo: ["button": button]
        )
        button.addTrackingArea(hoverArea)
    }

    // Handle mouse hover events
    override func mouseEntered(with event: NSEvent) {
        if let button = event.trackingArea?.userInfo?["button"] as? NSButton {
            animateButton(button, isHovered: true)
        }
    }

    override func mouseExited(with event: NSEvent) {
        if let button = event.trackingArea?.userInfo?["button"] as? NSButton {
            animateButton(button, isHovered: false)
        }
    }

    // Animate button on hover
    func animateButton(_ button: NSButton, isHovered: Bool) {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.toValue = isHovered ? 1.05 : 1.0
        animation.duration = 0.1
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        button.layer?.add(animation, forKey: "hoverEffect")
    }

    // Navigation actions
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
        view = NSView(frame: NSMakeRect(0, 0, 800, 600))  // Adjusted window size for macOS
        view.wantsLayer = true

         // Set a gradient background
        let navyBlue = NSColor(red: 69/255.0, green: 90/255.0, blue: 100/255.0, alpha: 1.0)
        let lightBlue = NSColor(red: 63/255.0, green: 82/255.0, blue: 119/255.0, alpha: 1.0)
        let steelblue = NSColor(red: 70/255.0, green: 130/255.0, blue: 180/255.0, alpha: 1.0)
        let midnightblue = NSColor(red: 25/255.0, green: 25/255.0, blue: 112/255.0, alpha: 1.0)
        
        // Create gradient layer
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            navyBlue.cgColor,
            lightBlue.cgColor,
            NSColor.black.cgColor
        ]
        gradientLayer.frame = view.bounds
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)  // Top-left corner
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)    // Bottom-right corner
        view.layer = gradientLayer

        // Animate gradient colors
        let colorAnimation = CABasicAnimation(keyPath: "colors")
        colorAnimation.fromValue = [
            navyBlue.cgColor,
            lightBlue.cgColor,
            NSColor.black.cgColor
        ]
        colorAnimation.toValue = [
            midnightblue.cgColor,
            steelblue.cgColor,
            NSColor.black.cgColor
        ]
        colorAnimation.duration = 1.5  // Animation duration in seconds
        colorAnimation.autoreverses = true  // Reverse the animation
        colorAnimation.repeatCount = .infinity  // Repeat indefinitely
        gradientLayer.add(colorAnimation, forKey: "colorChange")

        // Back button (top-left corner)
        let backButton = createButton(title: "Back", action: #selector(goBack), backgroundColor: navyBlue)
        view.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),  // 20 points from the left
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 20)          // 20 points from the top
        ])

        // Create image views and corresponding buttons
        let chords_image = NSImage(named: "chords_inst")
        let perc_image = NSImage(named: "percs")
        let express_image = NSImage(named: "express_inst")

        if chords_image == nil || perc_image == nil || express_image == nil {
            print("Error: Image not found!")
            return
        }

        // Chords image and button
        let chordsImageView = createCircularImageView(image: chords_image!, size: 450)
        let chordButton = createButton(title: "Chords", action: #selector(goToNextPage_chord), backgroundColor: navyBlue)
        view.addSubview(chordsImageView)
        view.addSubview(chordButton)
        NSLayoutConstraint.activate([
            chordsImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -450),  // Left side
            chordsImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -250),  // Slightly above center
            chordButton.topAnchor.constraint(equalTo: chordsImageView.bottomAnchor, constant: 10),  // Button below image
            chordButton.centerXAnchor.constraint(equalTo: chordsImageView.centerXAnchor)            // Centered below image
        ])

        // Percussion image and button
        let percImageView = createCircularImageView(image: perc_image!, size: 450)
        let percButton = createButton(title: "Percussion", action: #selector(goToNextPage_perc), backgroundColor: navyBlue)
        view.addSubview(percImageView)
        view.addSubview(percButton)
        NSLayoutConstraint.activate([
            percImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 450),     // Right side
            percImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -250),    // Slightly above center
            percButton.topAnchor.constraint(equalTo: percImageView.bottomAnchor, constant: 10),     // Button below image
            percButton.centerXAnchor.constraint(equalTo: percImageView.centerXAnchor)              // Centered below image
        ])

        // Expressive image and button
        let expressImageView = createCircularImageView(image: express_image!, size: 450)
        let expressButton = createButton(title: "Expressive", action: #selector(goToNextPage_express), backgroundColor: navyBlue)
        view.addSubview(expressImageView)
        view.addSubview(expressButton)
        NSLayoutConstraint.activate([
            expressImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),                // Center
            expressImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 300), // Below other images
            expressButton.topAnchor.constraint(equalTo: expressImageView.bottomAnchor, constant: 10), // Button below image
            expressButton.centerXAnchor.constraint(equalTo: expressImageView.centerXAnchor)        // Centered below image
        ])
    }

    // Helper function to create and style buttons
    func createButton(title: String, action: Selector, backgroundColor: NSColor) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.translatesAutoresizingMaskIntoConstraints = false
        styleButton(button, backgroundColor: backgroundColor)
        return button
    }

    // Button styling
    func styleButton(_ button: NSButton, backgroundColor: NSColor = .systemBlue) {
        button.bezelStyle = .rounded
        button.isBordered = false
        button.wantsLayer = true
        button.layer?.cornerRadius = 12  // Softer rounded corners
        button.layer?.backgroundColor = backgroundColor.cgColor
        button.contentTintColor = .white  // Text color
        button.font = NSFont.systemFont(ofSize: 18, weight: .medium)  // Adjusted font size
        button.widthAnchor.constraint(equalToConstant: 200).isActive = true  // Adjusted button width
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true  // Adjusted button height
    }

    // Helper function to create circular image views
    func createCircularImageView(image: NSImage, size: CGFloat) -> NSImageView {
        let imageView = NSImageView()
        imageView.image = image
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.wantsLayer = true
        imageView.layer?.cornerRadius = size / 2  // Make it circular
        imageView.layer?.masksToBounds = true
        imageView.widthAnchor.constraint(equalToConstant: size).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: size).isActive = true
        return imageView
    }

    // Navigation actions
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

class SharedData: ObservableObject {
    @Published var gesture_mappings: [String: String] = [:]
    @Published var section_mappings: [String: String] = [:]
}

struct ContentView: View {
    var gestures: [String]
    var chords: [String]
    var sections: [String]
    var chordTypes: [String]
    
    @ObservedObject var sharedData: SharedData
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(gradient: Gradient(colors: [
                Color(red: 69/255, green: 90/255, blue: 100/255),
                Color(red: 63/255, green: 82/255, blue: 119/255),
                Color.black
            ]),
            startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
            
            HStack {
                Spacer()
                
                // Chords List
                VStack {
                    sectionTitle("Chords")
                    scrollableList(items: chords, color: Color(red: 70/255, green: 130/255, blue: 180/255))
                }
                
                // Gesture Basket
                VStack {
                    sectionTitle("Gestures Basket")
                    gestureBasket()
                }
                
                // Chord Types List
                VStack {
                    sectionTitle("Chord Types")
                    scrollableList(items: chordTypes, color: Color(red: 255/255, green: 165/255, blue: 0/255))
                }
                
                // Sections Basket
                VStack {
                    sectionTitle("Sections Basket")
                    sectionBasket()
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    // MARK: - UI Components
    
    func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundColor(.white)
            .padding(.bottom, 10)
    }
    
    func scrollableList(items: [String], color: Color) -> some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .padding()
                        .background(color)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .onDrag {
                            NSItemProvider(object: item as NSString)
                        }
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    func gestureBasket() -> some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(gestures, id: \.self) { gesture in
                    HStack {
                        Text(gesture)
                            .foregroundColor(.white)
                        if let chord = sharedData.gesture_mappings[gesture] {
                            Text(chord)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .onDrop(of: ["public.text"], delegate: DropDelegate(destination: gesture, basket: $sharedData.gesture_mappings))
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    func sectionBasket() -> some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(sections, id: \.self) { section in
                    HStack {
                        Text(section)
                            .foregroundColor(.white)
                        if let chordType = sharedData.section_mappings[section] {
                            Text(chordType)
                                .padding()
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .onDrop(of: ["public.text"], delegate: DropDelegate(destination: section, basket: $sharedData.section_mappings))
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
}
// Drop Delegate
struct DropDelegate: SwiftUI.DropDelegate {
    let destination: String
    @Binding var basket: [String: String]

    func performDrop(info: DropInfo) -> Bool {
        guard let item = info.itemProviders(for: ["public.text"]).first else { return false }
        
        item.loadObject(ofClass: NSString.self) { (data, error) in
            if let text = data as? String {
                DispatchQueue.main.async {
                    basket[destination] = text
                }
            }
        }
        return true
    }

    func validateDrop(info: DropInfo) -> Bool {
        return info.itemProviders(for: ["public.text"]).isEmpty == false
    }
}

 
//CHORDS GEST MAP

class GestViewController_chords: NSViewController {
    var gestures = ["Open Palm", "Closed Fist", "Thumbs Up", "Thumbs Down", "Pointing Up", "Victory", "I Love You"]
    var chords = ["C", "C#", "Db", "D", "D#", "Eb", "E", "F", "F#", "Gb", "G", "G#", "Ab", "A", "A#", "Bb", "B"]
    var sections = ["Top", "Middle", "Bottom"]
    var chord_types = ["Major", "Minor", "Minor7", "Major7", "Dominant7", "Diminished7", "Hitchcock", "Augmented", "Augmented7#5", "AugmentedM7#", "Augmentedm7+", "Augmented7+", "Suspended4", "Suspended2", "Suspended47", "Suspended11", "Suspended4b9", "Suspendedb9", "Six", "Minor6", "Major6", "SevenSix", "SixNine", "Nine", "Major9", "Dominant7b9", "Dominant7#9", "Eleven", "Dominant7#11", "Minor11", "Thirteen", "Major13", "Minor13", "Dominant7b5", "NC", "Hendrix", "Power"]
    
    // Shared state
    var sharedData = SharedData()

    override func loadView() {
        // Create the main view
        view = NSView(frame: NSMakeRect(0, 0, 800, 600))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor

        // Embed the SwiftUI ContentView
        let contentView = ContentView(
            gestures: gestures,
            chords: chords,
            sections: sections,
            chordTypes: chord_types,
            sharedData: sharedData
        )
        
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingView)

        // Add constraints to the hosting view
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: view.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - DraggableTextField

class DraggableTextField: NSTextField {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.isSelectable = false
        self.isEditable = false
        self.isBordered = false
        self.backgroundColor = NSColor.clear
        self.registerForDraggedTypes([.string])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func mouseDown(with event: NSEvent) {
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(self.stringValue, forType: .string)
        
        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        draggingItem.setDraggingFrame(self.bounds, contents: self.stringValue)
        
        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }
}

extension DraggableTextField: NSDraggingSource {
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return .copy
    }
}

// Delegate for NSTextField drag and drop
extension GestViewController_chords: NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        // Handle text field updates after editing is done
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
                // Define the absolute path of the Python script
        let scriptPath = "/Users/joeyzhang/Documents/git/school/AirPlay-Instruments/AirplayInst/airplayinst/PythonBackEnd/main.py"

        startServer(scriptPath: scriptPath, instrumentType: "chord")
        
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

class RunController_express: NSViewController {
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

        startServer(scriptPath: scriptPath, instrumentType: "expressive")
        
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

