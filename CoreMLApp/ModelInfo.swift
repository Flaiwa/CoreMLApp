//
//  ModelManager.swift
//  CoreMLApp
//

import Observation
import CoreML
import OSLog

struct ModelInfo: Identifiable, Hashable {
    let id: String
    let url: URL
    let classNames: [String]
}

@Observable
final class ModelManager {

    static let shared = ModelManager()
    
    var availableModels: [ModelInfo] = []
    var selectedModel: ModelInfo?

    private let logger = Logger(subsystem: "de.telekom.routerdetection", category: "ModelManager")

    private init() {
        loadAvailableModels()
        // select automaticly first Ml modell
        if selectedModel == nil {
            selectedModel = availableModels.first
        }
    }

    private func loadAvailableModels() {
        guard let bundlePath = Bundle.main.resourcePath else { return }

        let fileManager = FileManager.default
        guard let contents = try? fileManager.contentsOfDirectory(atPath: bundlePath) else { return }

        for item in contents where item.hasSuffix(".mlmodelc") {
            let name = item.replacingOccurrences(of: ".mlmodelc", with: "")
            let url = Bundle.main.bundleURL.appendingPathComponent(item)

         
            let classes = extractClassNames(from: url)

            let info = ModelInfo(id: name, url: url, classNames: classes)
            availableModels.append(info)
            logger.info("Modell gefunden: \(name) mit \(classes.count) Klassen")
        }

        availableModels.sort { $0.id < $1.id }
    }
    
    private func extractClassNames(from url: URL) -> [String] {
        do {
            let model = try MLModel(contentsOf: url)

     
            if let metadata = model.modelDescription.metadata[.creatorDefinedKey] as? [String: String],
               let namesString = metadata["names"] {
                
                return parseClassNames(from: namesString)
            }

            if let classLabel = model.modelDescription.classLabels as? [String] {
                return classLabel
            }

            return []
        } catch {
            logger.error("Fehler beim Lesen der Klassen von \(url.lastPathComponent): \(error.localizedDescription)")
            return []
        }
    }

    private func parseClassNames(from namesString: String) -> [String] {
        var classes: [(Int, String)] = []

        let pattern = #"(\d+):\s*'([^']+)'"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let range = NSRange(namesString.startIndex..., in: namesString)
        let matches = regex.matches(in: namesString, range: range)

        for match in matches {
            if let indexRange = Range(match.range(at: 1), in: namesString),
               let nameRange = Range(match.range(at: 2), in: namesString),
               let index = Int(namesString[indexRange]) {
                classes.append((index, String(namesString[nameRange])))
            }
        }

        classes.sort { $0.0 < $1.0 }
        return classes.map { $0.1 }
    }

    func selectModel(_ model: ModelInfo) {
        selectedModel = model
        logger.info("Modell gewechselt zu: \(model.id)")
    }
}
#if DEBUG
extension ModelManager {
    func parseClassNamesForTesting(from string: String) -> [String] {
        return parseClassNames(from: string)
    }
}
#endif
