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
    
    public var currentModelName: String?
    
    private let modelManager = ModelManager.shared
    
    init() {
        //versuche in start camera direkt
        camera.onNewFrame = { [weak self] image in
            self?.frame = image
        }
        camera.onNewPixelBuffer = { [weak self] pixelBuffer in
            self?.performVisionInference(on: pixelBuffer)
        }
        loadSelectedModel()
        
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
    
    func loadSelectedModel(){
        guard let selected = modelManager.selectedModel else{
            logger.error("kein Modell ausgewählt")
            return
        }
        if currentModelName == selected.id{
            return
        }
        do{
            mlModel = try MLModel(contentsOf: selected.url)
            currentModelName = selected.id
            logger.info("MLModel geladen: \(selected.id)")
        } catch {
            logger.error("Fehler beim laden von \(selected.id): \(error.localizedDescription)")
            return
        }
        setUpVision()
    }

    private func setUpVision() {
           guard let mlModel = mlModel else {
               logger.error("Vision-Setup abgebrochen: MLModel ist nil.")
               return
           }
           do {
               vnModel = try VNCoreMLModel(for: mlModel)
               vnRequest = VNCoreMLRequest(model: vnModel!) { [weak self] request, error in
                   if let error = error {
                       self?.logger.error("Error processing vision results: \(error.localizedDescription)")
                       return
                   }
                   guard let observations = request.results as? [VNRecognizedObjectObservation] else {
                       self?.logger.error("unexpected event type from VNCoreMLRequest.")
                       return
                   }
                   var newDetections: [Detection] = []
                   for obs in observations {
                       let bestLabel = obs.labels.first?.identifier ?? "Object"
                       let confidence = obs.labels.first?.confidence ?? 0.0
                       let bbox = obs.boundingBox
                       newDetections.append(Detection(boundingBox: bbox, label: bestLabel, confidence: confidence))
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
               vnRequest?.imageCropAndScaleOption = .scaleFill
               logger.info("VNCoreMLModel und VNCoreMLRequest erfolgreich erstellt.")
           } catch {
               logger.error("Fehler bei Vision-Setup: \(error.localizedDescription)")
           }
       }
    
       private func performVisionInference(on pixelBuffer: CVPixelBuffer) {
           let now = Date()
           guard now.timeIntervalSince(lastInferenceTime) >= inferenceInterval else {
               return
           }
           lastInferenceTime = now
    
           guard let request = vnRequest else {
               logger.debug("Inference übersprungen: VNCoreMLRequest ist nil.")
               return
           }
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
