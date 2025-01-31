import Foundation
import AppKit
import Network

class SocketClient {
    private var connection: NWConnection?
    private var imageView: NSImageView! // Image view to display frames

    func start() {
        // Create an image view to display frames
        imageView = NSImageView(frame: CGRect(x: 0, y: 0, width: 640, height: 480))
        imageView.imageScaling = .scaleProportionallyUpOrDown

        // Create a window to display the image view
        let window = NSWindow(
            contentRect: imageView.frame,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.contentView = imageView
        window.makeKeyAndOrderFront(nil)

        // Start the Python server
        startPythonServer()

        // Wait for the server to start (adjust delay as needed)
        Thread.sleep(forTimeInterval: 2)

        // Connect to the Python server
        connectToServer()
    }

    private func startPythonServer() {
        print("Starting Python server")
        // Get the path to the Python script in the app bundle
        guard let scriptPath = Bundle.main.path(forResource: "graphics_server", ofType: "py") else {
            print("Python script not found in bundle")
            return
        }

        // Create a Process instance
        let process = Process()

        // Set the executable to the Python interpreter
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")

        // Set the arguments (path to the script)
        process.arguments = [scriptPath]

        // Set up output handling (optional)
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        // Handle output data (optional)
        outputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            if let output = String(data: data, encoding: .utf8) {
                print("Python Server Output: \(output)")
            }
        }

        // Launch the process
        do {
            try process.run()
            print("Python server started successfully")
        } catch {
            print("Failed to start Python server: \(error)")
        }
    }

    private func connectToServer() {
        // Create a connection to the server
        let host = NWEndpoint.Host("localhost")
        let port = NWEndpoint.Port(integerLiteral: 60003)
        connection = NWConnection(host: host, port: port, using: .tcp)

        connection?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("Connected to server")
                self.receiveFrame()
            case .failed(let error):
                print("Connection failed with error: \(error)")
            default:
                break
            }
        }

        connection?.start(queue: .global())
    }

    private func receiveFrame() {
        connection?.receive(minimumIncompleteLength: 8, maximumLength: 8) { (data, context, isComplete, error) in
            if let data = data, data.count == 8 {
                // Unpack the message size
                let messageSize = data.withUnsafeBytes { $0.load(as: UInt64.self) }

                // Receive the compressed frame data
                self.connection?.receive(minimumIncompleteLength: Int(messageSize), maximumLength: Int(messageSize)) { (frameData, context, isComplete, error) in
                    if let frameData = frameData {
                        // Decode the JPEG data into an image
                        if let image = NSImage(data: frameData) {
                            // Update the image view on the main thread
                            DispatchQueue.main.async {
                                self.imageView.image = image
                            }
                        }
                    }

                    // Continue receiving frames
                    self.receiveFrame()
                }
            }
        }
    }
}

// Start the client
func startClient() {
    // Start the client
    let client = SocketClient()
    client.start()

    // Keep the application running
    RunLoop.main.run()
}
