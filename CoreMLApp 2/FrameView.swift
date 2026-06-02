//
//  FrameView.swift
//  CoreMLApp
//

import SwiftUI

struct FrameView: View {
    public var image: CGImage?
    private let label = Text("frame")
    
    var body: some View {
        if let image = image{
            Image(image, scale: 1.0, orientation: .up, label: label)
        }
        else{
            Color.black
        }
    }
}

#Preview {
    FrameView()
}
