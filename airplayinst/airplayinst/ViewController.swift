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
/*
firstpage:
 1. Logo
 2. Name
 3. Sign in <button>
 4. Play as guest <button>
 */
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
        
        let percButton = NSButton(title: "Percussion", target: self, action: #selector(runChordsScript))
        percButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(percButton)
        NSLayoutConstraint.activate([
            percButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -300),
            percButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 215)
        ])
        let chordButton = NSButton(title: "Chords", target: self, action: #selector(runChordsScript))
        chordButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chordButton)
        NSLayoutConstraint.activate([
            chordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 300),
            chordButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 215)
        ])
        /*
        let backButton = NSButton(title: "Back", target: self, action: #selector())
        backButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 20),
            backButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 600)
        ])
        *
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
            chordsimageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
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
            percimageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            percimageView.widthAnchor.constraint(equalToConstant: 350),
            percimageView.heightAnchor.constraint(equalToConstant: 350)
        ])
        
        
    }
    
    @objc func runPercussionScript() {
        requestCameraPermission { [self] granted in
            if granted {
                print("Camera access granted. Running Python script...")
                runPythonScript(scriptName: "main.py")
            }
            else {
                print("Camera access denied.")
            }
        }
    }
    
    
    @objc func runChordsScript() {
        requestCameraPermission { [self] granted in
            if granted {
                print("Camera access granted. Running Python script...")
                runPythonScript(scriptName: "main.py")
            }
            else {
                print("Camera access denied.")
            }
        }
    }
    
    
    
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            // Request access
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(granted)
            }
        case .authorized:
            // Already authorized
            completion(true)
        case .denied, .restricted:
            // Access denied
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    func runPythonScript(scriptName: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/anaconda3/bin/python3") // Path to Python
        process.arguments = ["/Users/loganclarke/Desktop/AirPlay-Instruments-ImprovedFingerDetection-JAN2025/\(scriptName)"] // Full path to your script
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        let fileHandle = pipe.fileHandleForReading
        
        fileHandle.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                DispatchQueue.main.async {
                    print("Python Script Output: \(output)")
                }
            }
        }
        
        process.terminationHandler = { process in
            DispatchQueue.main.async {
                print("Python script terminated with exit code: \(process.terminationStatus)")
            }
            pipe.fileHandleForReading.readabilityHandler = nil // Stop reading
        }
        
        do {
            try process.run()
        } catch {
            print("Error running Python script: \(error)")
        }
    }
    
    
}
