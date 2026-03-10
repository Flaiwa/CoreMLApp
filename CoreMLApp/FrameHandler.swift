//
//  FrameHandler.swift
//  CoreMLApp
//
//  Created by Ihub Innopot on 10.03.26.
//

import AVFoundation
import CoreImage

final class FrameHandler: NSObject {
   
    var onNewFrame: ((CGImage) -> Void)?
    var onNewPixelBuffer: ((CVPixelBuffer) -> Void)?

    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let context = CIContext()
    private var isSessionConfigured = false

    // Requesting authorization to capture
    var isAuthorized: Bool {
        get async {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            var isAuthorized = status == .authorized
            if status == .notDetermined {
                isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
            }
            return isAuthorized
        }
    }

    // ViewModels starts Capture session
    func start() async {
        await setUpCaptureSession()
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else {return}
            if captureSession.isRunning {
                captureSession.stopRunning()
            }
        }
    }

    private func setUpCaptureSession() async {
        guard await isAuthorized else { return }

        sessionQueue.async { [weak self] in
            guard let self else {return}
            if !isSessionConfigured {
                let videoOutput = AVCaptureVideoDataOutput()

                guard let videoDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
                guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
                guard captureSession.canAddInput(videoDeviceInput) else { return }
                captureSession.addInput(videoDeviceInput)

                if captureSession.canAddOutput(videoOutput) {
                    videoOutput.setSampleBufferDelegate(self, queue: .init(label: "de.telekom.sampleBufferQueue"))
                    // important for using pixelbuffer for Vision
                    videoOutput.videoSettings = [
                        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                    ]
                    captureSession.addOutput(videoOutput)
                }

                videoOutput.connection(with: .video)?.videoRotationAngle = 90
                isSessionConfigured = true
            }

            captureSession.startRunning()
        }
    }
}
