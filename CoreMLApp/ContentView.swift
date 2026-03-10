//
//  ContentView.swift
//  CoreMLApp
//
//  Created by Ihub Innopot on 10.03.26.
//

import SwiftUI

struct ContentView: View {
    private var model = FrameHandler()
    
    var body: some View {
        VStack {
            // live camera
            FrameView(image: model.frame)
                .ignoresSafeArea()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
