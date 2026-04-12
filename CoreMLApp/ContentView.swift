//
//  ContentView.swift
//  CoreMLApp
//

import SwiftUI
 
struct ContentView: View {
    @State private var isShowingScanner = false
 
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
 
                VStack(spacing: 32) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 150))
                        .foregroundStyle(.green)
 
                    Text("Router Scanner")
                        .font(.largeTitle)
                        .fontWeight(.bold)
 
                    Text("Erkenne Router mit deiner Kamera")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
 
                    Button {
                        isShowingScanner = true
                    } label: {
                        Text("Scan starten")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .frame(maxWidth: 260)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .controlSize(.large)
                }
            }
            .fullScreenCover(isPresented: $isShowingScanner) {
                ScannerView()
            }
        }
    }
}
#Preview {
    ContentView()
}

