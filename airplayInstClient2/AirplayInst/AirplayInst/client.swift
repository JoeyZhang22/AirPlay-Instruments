import Foundation
import Network
import AppKit

class FrameReceiver: ObservableObject {
    private var connection: NWConnection?
    @Published var image: NSImage? // Published property to update the UI

    func start(host: String, port: Int) {
        // Create a connection to the server
        let nwHost = NWEndpoint.Host(host)
        let nwPort = NWEndpoint.Port(integerLiteral: UInt16(port))
        connection = NWConnection(host: nwHost, port: nwPort, using: .tcp)

        connection?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("Connected to server at \(host):\(port)")
                self.receiveFrameSize()
            case .failed(let error):
                print("Connection failed with error: \(error)")
            default:
                print("Connection state: \(state)")
            }
        }

        connection?.start(queue: .global())
    }

    func startClient(host: String, port: Int) {
        // Establish the client connection if not already connected
        if connection == nil {
            start(host: host, port: port)
        } else {
            print("Client already connected.")
        }
    }

    func stop() {
        connection?.cancel() // Cancel the connection
        connection = nil
        print("Frame receiver stopped")
    }

    private func receiveFrameSize() {
        // Receive the size of the incoming frame (8 bytes)
        connection?.receive(minimumIncompleteLength: 8, maximumLength: 8) { (data, context, isComplete, error) in
            if let data = data, data.count == 8 {
                // Unpack the message size (UInt64)
                let messageSize = data.withUnsafeBytes { $0.load(as: UInt64.self) }
                print("Receiving frame of size: \(messageSize)")

                // Receive the frame data
                self.receiveFrameData(remainingBytes: Int(messageSize))
            } else if let error = error {
                print("Error receiving frame size: \(error)")
            }
        }
    }

    private func receiveFrameData(remainingBytes: Int) {
        // Receive the frame data
        connection?.receive(minimumIncompleteLength: remainingBytes, maximumLength: remainingBytes) { (data, context, isComplete, error) in
            if let data = data, data.count == remainingBytes {
                // Decode the JPEG data into an NSImage
                if let image = NSImage(data: data) {
                    // Update the image on the main thread
                    DispatchQueue.main.async {
                        self.image = image
                    }
                } else {
                    print("Failed to decode frame")
                }

                // Continue receiving the next frame size
                self.receiveFrameSize()
            } else if let error = error {
                print("Error receiving frame data: \(error)")
            }
        }
    }
}
