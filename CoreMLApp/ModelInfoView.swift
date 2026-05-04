//
//  ModelInfoView.swift
//  CoreMLApp
//

import SwiftUI

struct ModelInfoView: View {
    @Environment(\.dismiss) private var dismiss

    private var modelManager = ModelManager.shared
    @State private var pendingSelection: ModelInfo?

    var body: some View {
        NavigationStack {
            List {
                
                Section("Verfügbare Modelle") {
                    ForEach(modelManager.availableModels) { model in
                        Button {
                            pendingSelection = model
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(model.id)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)

                                    Text("\(model.classNames.count) Klassen")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if model.id == modelManager.selectedModel?.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                    }
                }
                if let selected = modelManager.selectedModel {
                    Section("Aktives Modell") {
                        InfoRow(label: "Name", value: selected.id)
                        InfoRow(label: "Klassen", value: "\(selected.classNames.count)")
                    }

                    Section("Erkennbare Klassen") {
                        ForEach(selected.classNames, id: \.self) { name in
                            Text(name)
                        }
                    }
                }
            }
            .navigationTitle("Modell-Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .alert("Modell wechseln", isPresented: .init(
                get: { pendingSelection != nil },
                set: { if !$0 { pendingSelection = nil } }
            )) {
                Button("Abbrechen", role: .cancel) {
                    pendingSelection = nil
                }
                Button("OK") {
                    if let model = pendingSelection {
                        modelManager.selectModel(model)
                    }
                    pendingSelection = nil
                }
            } message: {
                if let model = pendingSelection {
                    Text("Möchtest du zu \"\(model.id)\" wechseln?")
                }
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
#Preview {
    ModelInfoView()
}
