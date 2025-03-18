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

    func start(scriptPath: String, instrumentType: String) {
        // Ensure the correct Python interpreter path
        let pythonPath = "/usr/bin/python3" // Adjust if necessary
        let ConfigFilePath: String = "gesture_mappings.json" // Default rn. Adjust when needed

        // Determine instrument mode argument
        var instrumentArg = "E" // Default to Expressive
        switch instrumentType.lowercased() {
        case "chord":
            instrumentArg = "C"
        case "percussion":
            instrumentArg = "P"
        case "expressive":
            instrumentArg = "E"
        default:
            print("Invalid instrument type provided. Defaulting to Expressive.")
        }
       
        // Create the Process instance
        process = Process()
        process?.launchPath = pythonPath
        
        // Pass -u, scriptPath, and other arguments (splitting each argument correctly)
        process?.arguments = [
            "-u",
            scriptPath,          // Path to the Python script
            "--instrument",
            instrumentArg,       // Instrument argument (e.g., --instrument C)
            "--config",          // Flag for the config file
            ConfigFilePath      // Path to the config file
        ]
        
        // Print the command being sent (for debugging)
        print("Command Line Arguments: \(process?.arguments ?? [])")

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
            print("Python server started successfully with instrument mode: \(instrumentType)")
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
