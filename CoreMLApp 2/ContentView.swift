//
//  ContentView.swift
//  CoreMLApp
//

import SwiftUI
 
struct ContentView: View {
    @State private var isShowingScanner = false
    @State private var isShowingModelInfo = false
 
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
 
                VStack(spacing: 32) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 150))
                        .foregroundStyle(Color.accentColor)
 
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
                    .tint(Color.accentColor)
                    .controlSize(.large)
                }
            }
            .overlay(alignment: .topLeading){
                Button{
                    isShowingModelInfo = true
                } label: {
                    Image(systemName: "info.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                        .padding(20)
                }
            }
            .fullScreenCover(isPresented: $isShowingScanner) {
                ScannerView()
            }
            .sheet(isPresented: $isShowingModelInfo){
                ModelInfoView()
            }
        }
    }
}
#Preview {
    ContentView()
}

