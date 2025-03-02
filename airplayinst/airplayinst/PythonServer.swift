//
//  PythonServer.swift
//  AirplayInst
//
//  Created by Joey Zhang on 2025-02-19.
//

import Foundation
import Combine

class PythonServer: ObservableObject {
    private var process: Process?
    @Published var isRunning: Bool = false // Published property to track server state

    func start() {
        // Define the absolute path of the Python script
        let scriptPath = "/Users/joeyzhang/Documents/git/school/AirPlay-Instruments/AirplayInst/airplayinst/PythonBackEnd/main.py"
        // Ensure the correct Python interpreter path
        let pythonPath = "/usr/bin/python3" // Adjust if necessary

        // Create the Process instance
        process = Process()
        process?.launchPath = pythonPath // Use `launchPath` for executing the Python interpreter
        
        // Set arguments for the Python script (no arguments if not needed)
        process?.arguments = ["-u", scriptPath] // `-u` for unbuffered output

        // Set the script’s directory as the working directory (important for relative paths)
        let scriptDirectory = (scriptPath as NSString).deletingLastPathComponent
        process?.currentDirectoryPath = scriptDirectory

        // Set up output handling
        let outputPipe = Pipe()
        process?.standardOutput = outputPipe
        process?.standardError = outputPipe

        // Read and print Python output
        outputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                print("Python Server Output: \(output)")
            }
        }

        // Launch the process
        do {
            try process?.run()
            isRunning = true
            print("Python server started successfully")
        } catch {
            print("Failed to start Python server: \(error)")
        }
    }

    func stop() {
        // Stop the server process
        process?.terminate()
        process = nil
        isRunning = false // Update the server state
        print("Python server stopped")
    }
}
