//
//  CameraViewModel.swift
//  CoreMLApp
//

import Observation
import CoreGraphics
import CoreML
import Vision
import VideoToolbox
import OSLog

struct Detection: Identifiable {
    let id = UUID()
    let boundingBox: CGRect
    let label: String
    let confidence: Float
}

@Observable
final class CameraViewModel {
    
    public var frame: CGImage?
    public var isRunning = false
   // detection list for the UI
    public var detections: [Detection] = []
    
    private let camera = FrameHandler()
    private var mlModel: MLModel?
    
    // Vision
    private var vnModel: VNCoreMLModel?
    private var vnRequest: VNCoreMLRequest?
    
    private let logger = Logger(subsystem: "de.telekom.routerdetection", category: "CameraViewModel")
    private let inferenceQueue = DispatchQueue(label: "de.telekom.routerdetection.inferenceQueue")
    
    // controll interval
    private var lastInferenceTime = Date(timeIntervalSince1970: 0)
    private let inferenceInterval: TimeInterval = 0.5
    
    
    public var lastDetectedRouter: String? = nil
    
    init() {
        //versuche in start camera direkt
        camera.onNewFrame = { [weak self] image in
            self?.frame = image
        }
        camera.onNewPixelBuffer = { [weak self] pixelBuffer in
            self?.performVisionInference(on: pixelBuffer)
        }
        loadModelIfNeeded()
        setUpVisionIfPossible()
    }
    
    func startCamera() async {
        guard !isRunning else { return }
        await camera.start()
        isRunning = true
    }
    
    func stopCamera() {
        guard isRunning else { return }
        camera.stop()
        isRunning = false
        frame = nil
    }

    private func loadModelIfNeeded() {
        if mlModel != nil { return }
        let modelName = "routerDetection"
        guard let url = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            logger.error("MLModel not found: \(modelName).mlmodelc missing in bundel")
            return
        }
        do {
            mlModel = try MLModel(contentsOf: url)
            logger.info("MLModel succesfull loaded: \(modelName).")
        } catch {
            logger.error("Error loading the MlModel \(modelName): \(error.localizedDescription)")
        }
    }
    
    private func setUpVisionIfPossible() {
        guard vnModel == nil else { return }
        guard let mlModel = mlModel else {
            logger.error("Vision-Setup aborted: MLModel is nil.")
            return
        }
        do {
            // create VNCoreMLModel and Request
            vnModel = try VNCoreMLModel(for: mlModel)
            vnRequest = VNCoreMLRequest(model: vnModel!) { [weak self] request, error in
                if let error = error {
                    self?.logger.error("Error processing vision results: \(error.localizedDescription)")
                    return
                }
                // result list converted to expected type
                guard let observations = request.results as? [VNRecognizedObjectObservation] else {
                    self?.logger.error("unexpected event type from VNCoreMLRequest.")
                    return
                }
                // detected routers exract bounding boxes and labels
                var newDetections: [Detection] = []
                for obs in observations {
                    // takes the top label for each observation
                    let bestLabel = obs.labels.first?.identifier ?? "Object"
                    let confidence = obs.labels.first?.confidence ?? 0.0
                    let bbox = obs.boundingBox
                    newDetections.append( Detection(boundingBox: bbox, label: bestLabel, confidence: confidence) )
                }
                
                DispatchQueue.main.async {
                    self?.detections = newDetections
                    if let first = newDetections.first {
                        self?.lastDetectedRouter = first.label
                    } else {
                        self?.lastDetectedRouter = nil
                    }
                }
            }
            // adjust image scaling
            vnRequest?.imageCropAndScaleOption = .scaleFill
            logger.info("VNCoreMLModel and VNCoreMLRequest succesfully created.")
        } catch {
            logger.error("error with set up Vision/CoreMl \(error.localizedDescription)")
        }
    }
    
    private func performVisionInference(on pixelBuffer: CVPixelBuffer) {
        // ceck each 0.5 second an inference
        let now = Date()
        guard now.timeIntervalSince(lastInferenceTime) >= inferenceInterval else {
            return
        }
        lastInferenceTime = now
        
        guard let request = vnRequest else {
            logger.debug("Inference übersprungen: VNCoreMLRequest ist nil.")
            return
        }
        // Vision-Request is async
        inferenceQueue.async { [weak self] in
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
            do {
                try handler.perform([request])
            } catch {
                self?.logger.error("Fehler bei Vision-Inference: \(error.localizedDescription)")
            }
        }
    }
}
