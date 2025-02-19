import SwiftUI

struct ContentView: View {
    @StateObject private var frameReceiver = FrameReceiver() // ObservableObject for receiving frames
    @StateObject private var pythonServer = PythonServer()   // ObservableObject for starting the server
    private let host = "localhost" // Replace with your server's host
    private let port = 60003       // Replace with your server's port
    private let delayInSeconds: Double = 2.0 // Delay duration before starting the client

    @State private var isClientStarted = false // To track if the client has started

    var body: some View {
        VStack {
            // Display the received frame
            if let image = frameReceiver.image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text(pythonServer.isRunning ? "Waiting for frames..." : "Server not running")
                    .font(.title)
                    .foregroundColor(.gray)
            }

            // Buttons to start/stop the server and client
            HStack {
                Button(action: {
                    pythonServer.start(host: host, port: port)
                }) {
                    Text("Start Server")
                        .padding()
                        .background(pythonServer.isRunning ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(pythonServer.isRunning) // Disable the button if the server is running

                Button(action: {
                    pythonServer.stop()
                    frameReceiver.stop() // Stop the frame receiver when the server stops
                    isClientStarted = false // Reset the client status
                }) {
                    Text("Stop Server")
                        .padding()
                        .background(pythonServer.isRunning ? Color.red : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!pythonServer.isRunning) // Disable the button if the server is not running
                
                // New button to start client with delay
                Button(action: {
                    // Delay the client connection attempt
                    DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) {
                        frameReceiver.start(host: host, port: port) // Start client after delay
                        isClientStarted = true // Set client status to started
                    }
                }) {
                    Text("Start Client")
                        .padding()
                        .background(pythonServer.isRunning && !isClientStarted ? Color.green : Color.gray) // Client can only start when server is running
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!pythonServer.isRunning || isClientStarted) // Disable the button if the server is not running or client is already started
            }
            .padding()
        }
        .padding()
        .onDisappear {
            // Stop the server and frame receiver when the view disappears
            pythonServer.stop()
            frameReceiver.stop()
        }
    }
}
