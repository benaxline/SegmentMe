//
//  ContentView.swift
//  SegmentMe
//
//  Created by Benjamin Axline on 6/20/24.
//

import SwiftUI
import Vision
import CoreML

struct ContentView: View {
    @State private var inputImage: NSImage?
    @State private var segmentedImage: NSImage?
    
    var body: some View {
        VStack {
            if let inputImage = inputImage {
                Image(nsImage: inputImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .padding()
            } else {
                Text("Select an Image")
                    .frame(maxHeight: 300)
                    .padding()
            }

            Button("Select Image") {
                selectImage()
            }
            .padding()

            if let segmentedImage = segmentedImage {
                Image(nsImage: segmentedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .padding()
            }

            Button("Segment Image") {
                if let inputImage = inputImage {
                    segmentImage(image: inputImage)
                }
            }
            .padding()
            .disabled(inputImage == nil)
        }
    }
    
    private func selectImage() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.allowedFileTypes = ["png", "jpg", "jpeg"]
        
        panel.begin { response in
            if response == .OK, let url = panel.url, let image = NSImage(contentsOf: url) {
                self.inputImage = image
            }
        }
    }

    private func segmentImage(image: NSImage) {
        guard let model = try? DeepLabV3(configuration: .init()),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return
        }

        let ciImage = CIImage(cgImage: cgImage)
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])

        do {
            let request = VNCoreMLRequest(model: try VNCoreMLModel(for: model.model)) { request, error in
                if let results = request.results as? [VNPixelBufferObservation], let pixelBuffer = results.first?.pixelBuffer {
                    self.segmentedImage = NSImage(pixelBuffer: pixelBuffer)
                }
            }
            try handler.perform([request])
        } catch {
            print("Failed to perform image segmentation: \(error)")
        }
    }
}


#Preview {
    ContentView()
}
