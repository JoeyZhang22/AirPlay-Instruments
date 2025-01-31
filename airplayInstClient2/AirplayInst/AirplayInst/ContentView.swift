import SwiftUI

struct ContentView: View {
    @StateObject private var frameReceiver = FrameReceiver() // ObservableObject
    private let host = "localhost" // Replace with your server's host
    private let port = 60003       // Replace with your server's port

    var body: some View {
        VStack {
            if let image = frameReceiver.image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("Waiting for frames...")
                    .font(.title)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .onAppear {
            // Start receiving frames when the view appears
            frameReceiver.start(host: host, port: port)
        }
    }
}
