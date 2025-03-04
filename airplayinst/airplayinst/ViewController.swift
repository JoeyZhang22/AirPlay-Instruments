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
        
        let percButton = NSButton(title: "Percussion", target: self, action: #selector(goToNextPage))
        percButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(percButton)
        NSLayoutConstraint.activate([
            percButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -300),
            percButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 215)
        ])
        let chordButton = NSButton(title: "Chords", target: self, action: #selector(goToNextPage))
        chordButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chordButton)
        NSLayoutConstraint.activate([
            chordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 300),
            chordButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 215)
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
    @objc func goToNextPage() {
        let runController = GestViewController_chords()
        self.view.window?.contentViewController = runController
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

// Gesture mapping view - Chords

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
        let runconc = RunController()
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


 
 /* Gesture mapping view - Percs
  
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

        // Configure input
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

        // Configure output
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


class RunController: NSViewController {
    override func loadView() {
        let mainView = NSView()
        mainView.wantsLayer = true
        mainView.layer?.backgroundColor = NSColor.black.cgColor
        
        
        
        
    
        // Create Camera View
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
        let logicButton = NSButton(title: "Start Logic", target: self, action: #selector(startLogicPro))
                logicButton.frame = NSRect(x: 20, y: 20, width: 100, height: 40)
                logicButton.bezelStyle = .rounded
                mainView.addSubview(logicButton)

                self.view = mainView
            }

        @objc private func startLogicPro() {
            let appPath = URL(fileURLWithPath: "/Applications/Logic Pro.appm")
            let workspace = NSWorkspace.shared
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.arguments = ["-empty"]
            do {
                try NSWorkspace.shared.openApplication(at: appPath, configuration: configuration)
                    print("Logic Pro started successfully!")
            }
            catch {
                print("Failed to start Logic Pro.")
            }
            
        }
}
