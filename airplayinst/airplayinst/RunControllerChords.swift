import Cocoa
import AVFoundation
import AppKit
import Foundation
import CoreMIDI
import SQLite3
import CoreGraphics
import Combine
import SwiftUI

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
