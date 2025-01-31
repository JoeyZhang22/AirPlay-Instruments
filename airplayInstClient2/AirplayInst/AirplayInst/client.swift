//
//  client.swift
//  AirplayInst
//
//  Created by Joey Zhang on 2025-01-24.
//

import Foundation
import Network
import AppKit
import SwiftUI

class FrameReceiver: ObservableObject {
    private var connection: NWConnection?
    @Published var image: NSImage? // Published property to update the UI

    func start(host: String, port: Int) {
        // Connect to the server
        connectToServer(host: host, port: port)
    }

    private func connectToServer(host: String, port: Int) {
        let host = NWEndpoint.Host("localhost")
        let port = NWEndpoint.Port(integerLiteral: 60003)
        connection = NWConnection(host: host, port: port, using: .tcp)

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
