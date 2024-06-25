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
        panel.allowedContentTypes = [.png, .jpeg]
        
        panel.begin { response in
            if response == .OK, let url = panel.url, let image = NSImage(contentsOf: url) {
                self.inputImage = image
            }
        }
    }

    private func segmentImage(image: NSImage) {
        // Ensure the model is loaded and the image is available as CGImage
        guard let model = try? DeepLabV3(configuration: .init()),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("Failed to load model or image.")
            return
        }

        let ciImage = CIImage(cgImage: cgImage)
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])

        do {
            let visionModel = try VNCoreMLModel(for: model.model)
            let request = VNCoreMLRequest(model: visionModel) { request, error in
                if let error = error {
                    print("Error during segmentation: \(error.localizedDescription)")
                    return
                }
                
                guard let results = request.results as? [VNPixelBufferObservation], !results.isEmpty else {
                    print("No valid results found.")
                    return
                }
                
                if let pixelBuffer = results.first?.pixelBuffer {
                    // Verify pixel buffer content
                    print("Pixel Buffer Width: \(CVPixelBufferGetWidth(pixelBuffer))")
                    print("Pixel Buffer Height: \(CVPixelBufferGetHeight(pixelBuffer))")

                    if let segmentedImage = self.convert(pixelBuffer: pixelBuffer) {
                        self.segmentedImage = segmentedImage
                        print("Segmentation successful, image updated.")
                    } else {
                        print("Error in converting image.")
                    }
                } else {
                    print("No pixel buffer found in results.")
                }
            }
            try handler.perform([request])
        } catch {
            print("Failed to perform image segmentation: \(error)")
        }
    }

    private func convert(pixelBuffer: CVPixelBuffer) -> NSImage? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            print("Failed to get base address of pixel buffer.")
            return nil
        }
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            print("Failed to create CGContext.")
            return nil
        }

        guard let cgImage = context.makeImage() else {
            print("Failed to create CGImage from CGContext.")
            return nil
        }

        return NSImage(cgImage: cgImage, size: NSSize(width: width, height: height))
    }
}

#Preview {
    ContentView()
}
