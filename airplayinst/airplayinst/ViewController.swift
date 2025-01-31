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
import Network


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
//        let runController = RunController()
//        self.view.window?.contentViewController = runController
        
        startClient()
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

/*
 Gesture mapping view - Chords
 
 


class GestViewController_chords: NSViewController {
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

 
 Gesture mapping view - Percs
 
 


class GestViewController_percs: NSViewController {
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



 
 Gesture mapping view - expressive
 



class GestViewController_expressive: NSViewController {
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


*/


/*
 
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
