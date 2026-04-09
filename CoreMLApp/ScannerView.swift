//
//  ScannerView.swift
//  CoreMLApp
//

import SwiftUI

struct ScannerView: View {
    @State private var viewModel = CameraViewModel()

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
    
            FrameView(image: viewModel.frame)
                .ignoresSafeArea()

            GeometryReader { geometry in
                ForEach(viewModel.detections) { det in
                    let rect = det.boundingBox
                    let boxWidth  = rect.width  * geometry.size.width
                    let boxHeight = rect.height * geometry.size.height
                    let boxX = rect.minX * geometry.size.width
                    let boxY = (1 - rect.minY - rect.height) * geometry.size.height

                    ZStack(alignment: .topLeading) {
                        Rectangle()
                            .stroke(Color.red, lineWidth: 2)
                            .frame(width: boxWidth, height: boxHeight)

                        Text(String(format: "%@ (%.0f%%)", det.label, det.confidence * 100))
                            .font(.caption).bold()
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.green.opacity(0.7))
                    }
                    .position(x: boxX + boxWidth/2, y: boxY + boxHeight/2)
                }
            }

            VStack {
                HStack {
                    Button {
                        viewModel.stopCamera()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                            .padding(20)
                    }
                    Spacer()
                }
                Spacer()
            }
        }
        .onAppear {
            Task {
                await viewModel.startCamera()
            }
        }
        .onDisappear {
            viewModel.stopCamera()
        }
    }
}

#Preview {
    ScannerView()
}
