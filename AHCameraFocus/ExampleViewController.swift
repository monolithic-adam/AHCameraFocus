//
//  ExampleViewController.swift
//  AHCameraFocus
//
//  Created by ahenry on 2018/04/20.
//  Copyright © 2018 Monolithic. All rights reserved.
//

import UIKit
import AVFoundation

class ExampleViewController: UIViewController {
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var device: AVCaptureDevice!
    private let photoOutput = AVCapturePhotoOutput()

    let cameraFocusViewController = AHCameraFocusViewController()
    let previewView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        previewView.frame = self.view.frame
        self.view.addSubview(previewView)

        self.setupSession()

        self.view.addSubview(cameraFocusViewController.view)
        cameraFocusViewController.device = self.device
        cameraFocusViewController.enablePint()
    }

    private func setupSession() {
        if let device = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: device) {
            self.device = device
            if device.isFocusModeSupported(.continuousAutoFocus) {
                try?    device.lockForConfiguration()
                device.focusMode = .continuousAutoFocus
                device.unlockForConfiguration()
            }
            session.addInput(input)
        }

        session.sessionPreset = .photo
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: session) as AVCaptureVideoPreviewLayer
        previewLayer.frame = self.view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        previewView.layer.addSublayer(previewLayer)

        session.startRunning()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { _ in
            let currentDevice: UIDevice = UIDevice.current
            let orientation: UIDeviceOrientation = currentDevice.orientation
            self.previewLayer.frame = self.view.bounds
        }, completion: nil)
    }

    func getOrientation() -> AVCaptureVideoOrientation {
        switch UIDevice.current.orientation {
        case .portrait:
            return .portrait
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        default:
            return .portrait
        }
    }
}
