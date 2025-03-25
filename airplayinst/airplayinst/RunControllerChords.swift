import Cocoa
import AVFoundation
import AppKit
import Foundation
import CoreMIDI
import SQLite3
import CoreGraphics
import Combine
import SwiftUI
import Foundation



class RunController: NSViewController {
    private weak var previousViewController: NSViewController?

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

    private let instrumentType: String
    
    // Initialize with instrument type
    init(instrumentType: String = "chord", previousViewController: NSViewController? = nil) {
        self.instrumentType = instrumentType
        self.previousViewController = previousViewController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.instrumentType = "chord" // Default value
        super.init(coder: coder)
    }
    
    override func loadView() {
        runAppleScript()
        let scriptPath = "/Users/joeyzhang/Documents/git/school/AirPlay-Instruments/AirplayInst/airplayinst/PythonBackEnd/main.py"
        startServer(scriptPath: scriptPath, instrumentType: instrumentType)

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
        buttonStack.spacing = 300 // Acts as minimum, since fillEqually enforces equal widths
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        bottomContainerView.addSubview(buttonStack)
    }
    
    private func setupConstraints(for mainView: NSView) {
            NSLayoutConstraint.activate([
                // Container layout
                topContainerView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor),
                topContainerView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor),
                topContainerView.topAnchor.constraint(equalTo: mainView.safeAreaLayoutGuide.topAnchor),
                topContainerView.heightAnchor.constraint(equalToConstant: 50),
                
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
                imageView.leadingAnchor.constraint(equalTo: middleContainerView.leadingAnchor, constant: 20),
                imageView.trailingAnchor.constraint(equalTo: middleContainerView.trailingAnchor, constant: -20),
                imageView.topAnchor.constraint(equalTo: middleContainerView.topAnchor, constant: 10),
                imageView.bottomAnchor.constraint(equalTo: middleContainerView.bottomAnchor, constant: -10),
//
//              // Bottom container contents
//                 buttonStack.leadingAnchor.constraint(equalTo: bottomContainerView.leadingAnchor, constant: 20),
//                 buttonStack.trailingAnchor.constraint(equalTo: bottomContainerView.trailingAnchor, constant: -20),
//                 buttonStack.centerYAnchor.constraint(equalTo: bottomContainerView.centerYAnchor),
//                 buttonStack.heightAnchor.constraint(equalToConstant: 50),

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
        guard let window = self.view.window else { return }
        
        // if let previousVC = previousViewController {
        //     window.contentViewController = previousVC
        // } else {
        //     // Fallback - create new GestViewController with current instrument type
        //     window.contentViewController = GestViewController(instrumentType: self.instrumentType)
        // }
        // Return to the previous view controller if it exists
        window.contentViewController = NextViewController()
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
        if pythonServer.isRunning {
            statusLabel.stringValue = isClientStarted ? "Receiving frames..." : "Server running"
        } else {
            statusLabel.stringValue = "Server not running"
        }
    }
}

// Helper extension for constraint priorities
extension NSLayoutConstraint {
    func withPriority(_ priority: NSLayoutConstraint.Priority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}


class SharedData: ObservableObject {
    @Published var gesture_mappings: [String: String] = [:]
    @Published var section_mappings: [String: String] = [:]

    // Generate JSON and save to file
    // Generate JSON and save to file
    func saveMappingsToJSON() {
        // 1. Create an ordered array for chord types
        let orderedChordTypes = [
            section_mappings["Top"],
            section_mappings["Middle"], 
            section_mappings["Bottom"]
        ].compactMap { $0 } // Remove nil values if any section is missing
        
        // 2. Prepare the JSON dictionary with ordered data
        let jsonData: [String: Any] = [
            "gesture_to_chord": gesture_mappings,
            "chord_types": orderedChordTypes
        ]

        do {
            // 3. Serialize with sorted keys to maintain order
            let jsonData = try JSONSerialization.data(
                withJSONObject: jsonData, 
                options: [.prettyPrinted, .sortedKeys]
            )
            
            let filePath = "/Users/joeyzhang/Documents/git/school/AirPlay-Instruments/AirplayInst/airplayinst/PythonBackEnd/DataProcessing/gesture_mappings.json"
            let fileURL = URL(fileURLWithPath: filePath)
            try jsonData.write(to: fileURL)
            print("JSON file saved successfully at: \(filePath)")
            
            // 4. Print verification of order
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Generated JSON:\n\(jsonString)")
            }
        } catch {
            print("Error saving JSON: \(error.localizedDescription)")
        }
    }

    // default Mapping function
    func setDefaultMappings() {
        // Default gesture to chord mappings
        gesture_mappings = [
            "Open_Palm": "C",
            "Closed_Fist": "D",
            "Thumb_Up": "E",
            "Thumb_Down": "F",
            "Pointing_Up": "G",
            "Victory": "A",
            "ILoveYou": "B"
        ]
        
        // Default section to chord type mappings
        section_mappings = [
            "Top": "Major",
            "Middle": "Minor",
            "Bottom": "Dominant7"
        ]
    }

}

struct ContentView: View {
    let gestures: [String]
    let chords: [String]
    let sections: [String]
    let chordTypes: [String]
    @ObservedObject var sharedData: SharedData
    let instrumentType: String
    
    weak var gestViewController: GestViewController?

    // State variable to control navigation
    @State private var navigateToRunController = false
    
    // Define lightBlue color
    let lightBlue = NSColor(red: 63/255.0, green: 82/255.0, blue: 119/255.0, alpha: 1.0)
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(gradient: Gradient(colors: [
                    Color(red: 69/255, green: 90/255, blue: 100/255),
                    Color(red: 63/255, green: 82/255, blue: 119/255),
                    Color.black
                ]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
                
                VStack {
                    // Title based on instrument type
                    Text(instrumentType == "chord" ? "Chord Mapping" : "Expressive Mapping")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // Main content
                    HStack(alignment: .top, spacing: 40) {
                        // Chords List
                        VStack {
                            sectionTitle("Chords")
                            scrollableList(items: chords, color: Color(red: 70/255, green: 130/255, blue: 180/255))
                        }
                        .frame(minWidth: 200, maxWidth: 250)
                        
                        // Gesture Basket
                        VStack {
                            sectionTitle("Gestures Basket")
                            gestureBasket()
                        }
                        .frame(minWidth: 200, maxWidth: 250)
                        
                        // Chord Types List
                        VStack {
                            sectionTitle("Chord Types")
                            scrollableList(items: chordTypes, color: Color(red: 255/255, green: 165/255, blue: 0/255))
                        }
                        .frame(minWidth: 200, maxWidth: 250)
                        
                        // Sections Basket
                        VStack {
                            sectionTitle("Sections Basket")
                            sectionBasket()
                        }
                        .frame(minWidth: 200, maxWidth: 250)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                    
                    // Buttons
                    VStack(spacing: 15) {
                        Button(action: {
                            sharedData.saveMappingsToJSON()
                            navigateToRunController = true
                        }) {
                            Text(instrumentType == "chord" ? "Map Chords" : "Map Expressive")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 250, height: 50)
                                .background(Color(lightBlue))
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            sharedData.setDefaultMappings()
                        }) {
                            Text("Default Mapping")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 250, height: 50)
                                .background(Color(lightBlue))
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationDestination(isPresented: $navigateToRunController) {
                RunControllerWrapper(
                    instrumentType: instrumentType,
                    gestViewController: self.gestViewController
                )
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
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
            VStack(spacing: 15) {  // Increased spacing between items
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .padding(10)  // More padding
                        .frame(maxWidth: .infinity)  // Full width
                        .background(color)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .onDrag {
                            NSItemProvider(object: item as NSString)
                        }
                }
            }
            .padding(.horizontal, 5)  // Inner padding
        }
        .frame(maxHeight: .infinity)
    }
    
    func gestureBasket() -> some View {
        ScrollView {
            VStack(spacing: 15) {  // Increased spacing
                ForEach(gestures, id: \.self) { gesture in
                    HStack {
                        Text(gesture)
                            .foregroundColor(.white)
                            .frame(minWidth: 120, alignment: .leading)  // Minimum width for gesture names
                        
                        if let chord = sharedData.gesture_mappings[gesture] {
                            Text(chord)
                                .padding(10)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity)  // Full width
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .onDrop(of: ["public.text"], 
                           delegate: DropDelegate(
                            destination: gesture, 
                            basket: $sharedData.gesture_mappings,
                            allowedTypes: chords
                           ))
                }
            }
            .padding(.horizontal, 5)
        }
        .frame(maxHeight: .infinity)
    }
    
    func sectionBasket() -> some View {
        ScrollView {
            VStack(spacing: 15) {  // Increased spacing
                ForEach(sections, id: \.self) { section in
                    HStack {
                        Text(section)
                            .foregroundColor(.white)
                            .frame(minWidth: 120, alignment: .leading)  // Minimum width for section names
                        
                        if let chordType = sharedData.section_mappings[section] {
                            Text(chordType)
                                .padding(10)
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity)  // Full width
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .onDrop(of: ["public.text"], 
                           delegate: DropDelegate(
                            destination: section, 
                            basket: $sharedData.section_mappings,
                            allowedTypes: chordTypes
                           ))
                }
            }
            .padding(.horizontal, 5)
        }
        .frame(maxHeight: .infinity)
    }
}

// Wrapper to present RunController_chords in SwiftUI
struct RunControllerWrapper: NSViewControllerRepresentable {
    let instrumentType: String
    weak var gestViewController: GestViewController?  // Reference to parent view controller
    
    init(instrumentType: String, gestViewController: GestViewController? = nil) {
        self.instrumentType = instrumentType
        self.gestViewController = gestViewController
    }
    
    func makeNSViewController(context: Context) -> RunController {
        // Remove back button when transitioning to RunController
        gestViewController?.removeBackButton()
        return RunController(instrumentType: instrumentType)
    }
    
    func updateNSViewController(_ nsViewController: RunController, context: Context) {
        // No updates needed
    }
}

// Drop Delegate
// Enhanced Drop Delegate with type checking
struct DropDelegate: SwiftUI.DropDelegate {
    let destination: String
    @Binding var basket: [String: String]
    let allowedTypes: [String]  // Array of allowed items for this drop target
    
    func performDrop(info: DropInfo) -> Bool {
        guard let item = info.itemProviders(for: ["public.text"]).first else { return false }
        
        item.loadObject(ofClass: NSString.self) { (data, error) in
            if let text = data as? String {
                DispatchQueue.main.async {
                    // Only accept the drop if the item is in allowedTypes
                    if allowedTypes.contains(text) {
                        basket[destination] = text
                    }
                }
            }
        }
        return true
    }

    func validateDrop(info: DropInfo) -> Bool {
        guard let item = info.itemProviders(for: ["public.text"]).first else { return false }
        
        // Create a semaphore to wait for the async check
        let semaphore = DispatchSemaphore(value: 0)
        var isValid = false
        
        item.loadObject(ofClass: NSString.self) { (data, error) in
            if let text = data as? String {
                isValid = allowedTypes.contains(text)
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        return isValid
    }
}

//CHORDS GEST MAP
class GestViewController: NSViewController {
    let instrumentType: String  // "chord" or "expressive"
    private let gestures = ["Open_Palm", "Closed_Fist", "Thumb_Up", "Thumb_Down", "Pointing_Up" , "Victory", "ILoveYou"]
    private let chords = ["C", "C#", "Db", "D", "D#", "Eb", "E", "F", "F#", "Gb", "G", "G#", "Ab", "A", "A#", "Bb", "B"]
    private let sections = ["Top", "Middle", "Bottom"]
    private let chordTypes = ["Major", "Minor", "Minor7", "Major7", "Dominant7", "Diminished7", "Hitchcock", "Augmented", "Augmented7#5", "AugmentedM7#", "Augmentedm7+", "Augmented7+", "Suspended4", "Suspended2", "Suspended47", "Suspended11", "Suspended4b9", "Suspendedb9", "Six", "Minor6", "Major6", "SevenSix", "SixNine", "Nine", "Major9", "Dominant7b9", "Dominant7#9", "Eleven", "Dominant7#11", "Minor11", "Thirteen", "Major13", "Minor13", "Dominant7b5", "NC", "Hendrix", "Power"]
    private let sharedData: SharedData = SharedData()

    //track back button
    private var backButton: NSButton? // Make this optional

    //color
    private let steelblue = NSColor(red: 70/255.0, green: 130/255.0, blue: 180/255.0, alpha: 1.0)
    
    init(instrumentType: String) {
        self.instrumentType = instrumentType
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let contentView = ContentView(
        gestures: gestures,
        chords: chords,
        sections: sections,
        chordTypes: chordTypes,
        sharedData: sharedData,
        instrumentType: instrumentType,
        gestViewController: self  // Pass self reference
    )
        
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        self.view = NSView()
        self.view.addSubview(hostingView)
        
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: view.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Add back button
        // let backButton = createButton(title: "Back", action: #selector(goBack))
        // backButton.frame = CGRect(x: 20, y: 20, width: 80, height: 30)
        // self.view.addSubview(backButton)
    }

    func removeBackButton() {
        print("Current subviews: \(view.subviews)")
        backButton?.removeFromSuperview()
        print("Subviews after removal: \(view.subviews)")
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

    @objc func goBack() {
        guard let window = view.window else { return }
        
        // Return to the previous view controller if it exists
        window.contentViewController = NextViewController()
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
extension GestViewController: NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        // Handle text field updates after editing is done
    }
}
