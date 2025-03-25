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
        
        // stackView.addArrangedSubview(sign_up_button)
        // stackView.addArrangedSubview(sign_in_button)
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
        // Create the main view
        view = NSView(frame: NSMakeRect(0, 0, 800, 600))  // Initial size, but will scale
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
        let chordsImageView = createCircularImageView(image: chords_image!, size: view.bounds.width * 0.4) // 30% of view width
        let chordButton = createButton(title: "Chords", action: #selector(goToNextPage_chord), backgroundColor: navyBlue)
        view.addSubview(chordsImageView)
        view.addSubview(chordButton)
        NSLayoutConstraint.activate([
            chordsImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60),  // 20 points from the left
            chordsImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -view.bounds.height * 0.1),  // 10% above center
            chordButton.topAnchor.constraint(equalTo: chordsImageView.bottomAnchor, constant: 10),  // Button below image
            chordButton.centerXAnchor.constraint(equalTo: chordsImageView.centerXAnchor)            // Centered below image
        ])

        // Percussion image and button
        let percImageView = createCircularImageView(image: perc_image!, size: view.bounds.width * 0.4) // 30% of view width
        let percButton = createButton(title: "Percussion", action: #selector(goToNextPage_perc), backgroundColor: navyBlue)
        view.addSubview(percImageView)
        view.addSubview(percButton)
        NSLayoutConstraint.activate([
            percImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60),  // 20 points from the right
            percImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -view.bounds.height * 0.1),  // 10% above center
            percButton.topAnchor.constraint(equalTo: percImageView.bottomAnchor, constant: 10),     // Button below image
            percButton.centerXAnchor.constraint(equalTo: percImageView.centerXAnchor)              // Centered below image
        ])

        // Expressive image and button
        let expressImageView = createCircularImageView(image: express_image!, size: view.bounds.width * 0.4)
        let expressButton = createButton(title: "Expressive", action: #selector(goToNextPage_express), backgroundColor: navyBlue)
        view.addSubview(expressImageView)
        view.addSubview(expressButton)
        NSLayoutConstraint.activate([
            expressImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),                // Center
            expressImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -view.bounds.height * 0.3), // 10% from bottom
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
    // In your previous view controller:
    @objc func goToNextPage_chord() {
        let gestVC = GestViewController(instrumentType: "chord")
        self.view.window?.contentViewController = gestVC
    }

    @objc func goToNextPage_express() {
        let gestVC = GestViewController(instrumentType: "expressive")
        self.view.window?.contentViewController = gestVC
    }

    @objc func goToNextPage_perc() {
        // Keep percussion separate if it has different requirements
        let percVC = RunController_percs()
        self.view.window?.contentViewController = percVC
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
