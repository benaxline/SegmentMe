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
                    .frame(minHeight: 500)
                    .padding()
            } else {
                Text("Select an Image")
                    .frame(minHeight: 500)
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
                    .frame(minHeight: 500)
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
        // load model
        var model = DeepLabV3()   // depreicated
        var request: VNCoreMLRequest?
        
        // setup model
        if let visionModel = try? VNCoreMLModel(for: model.model) {
            request = VNCoreMLRequest(model: visionModel/*, completionHandler: visionRequestDidComplete*/)
            request?.imageCropAndScaleOption = .scaleFill
        } else {
            fatalError()
        }
        
        // prepare the input
        //resize image and convert to CVPixelBuffer
        var imgRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        let resizedImage = image.resize(newSize: NSSize(width: 513, height: 513))
        // to CGImage
        let cgResizedImage = resizedImage.cgImage(forProposedRect: &imgRect, context: nil, hints: nil)
        
        
        guard let input = try? DeepLabV3Input(imageWith: cgResizedImage!) else {
            print("fail: input preparation")
            return
        }
        
        
        // pass input through model
        guard let prediction = try? model.prediction(input: input) else {
            print("fail: predition")
            return
        }
        
        let multiArray = prediction.semanticPredictions

        // Convert MLMultiArray to CVPixelBuffer
        let pixelFormatType = kCVPixelFormatType_32BGRA
        let bufferPointer = UnsafeMutableRawPointer(multiArray.dataPointer)

        var pixelBufferOut: CVPixelBuffer?
        let status = CVPixelBufferCreateWithBytes(
            kCFAllocatorDefault,
            Int(multiArray.shape[0].intValue),
            Int(multiArray.shape[1].intValue),
            pixelFormatType,
            bufferPointer,
            multiArray.strides[0].intValue,
            nil, // You can provide a release callback here if needed
            nil,
            nil,
            &pixelBufferOut
        )

        guard status == kCVReturnSuccess, let outputPixelBuffer = pixelBufferOut else {
            fatalError("Unable to create CVPixelBuffer from MLMultiArray.")
        }
        // outputPixelBuffer is the pixel buffer
        
//        // output
//        let output = DeepLabV3Output(semanticPredictions: prediction.semanticPredictions)
//        guard let buffer = output.featureValue(for: "semanticPredictions")?.multiArrayValue?.pixelBuffer else {
//            print("Buffer not computed")
//            return
//        }
//        self.segmentedImage = NSImage(pixelBuffer: buffer)
//        
        let ciContext = CIContext()
        let ciOutImage = CIImage(cvImageBuffer: outputPixelBuffer)
        
        if let cgOutImage = ciContext.createCGImage(ciOutImage, from: ciOutImage.extent){
            let outImage = NSImage(cgImage: cgOutImage, size: NSSize(width: 513, height: 513))
            self.segmentedImage = outImage
            print("segmentedImage assigned")
        } else {
            print("could not create CGImage")
        }

    }
    
    

//    private func segmentImage(image: NSImage) {
//        // Ensure the model is loaded and the image is available as CGImage
//        guard let model = try? DeepLabV3(configuration: .init()) else {
//            print("Failed to load model.")
//            return
//        }
//        
//        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
//            print("Failed to create CGImage from input image.")
//            return
//        }
//
//        // Log model information
//        print("Model loaded successfully: \(model)")
//        
//        // Preprocess the image
//        guard let preprocessedImage = preprocessImage(cgImage: cgImage) else {
//            print("Failed to preprocess image.")
//            return
//        }
//        
//        // Log preprocessed image information
//        print("Preprocessed CIImage: \(preprocessedImage)")
//
//        let handler = VNImageRequestHandler(ciImage: preprocessedImage, options: [:])
//
//        do {
//            let visionModel = try VNCoreMLModel(for: model.model)
//            let request = VNCoreMLRequest(model: visionModel) { request, error in
//                if let error = error {
//                    print("Error during segmentation: \(error.localizedDescription)")
//                    return
//                }
//                
//                guard let results = request.results as? [VNPixelBufferObservation], !results.isEmpty else {
//                    print("No valid results found.")
//                    return
//                }
//                
//                if let pixelBuffer = results.first?.pixelBuffer {
//                    // Verify pixel buffer content
//                    print("Pixel Buffer Width: \(CVPixelBufferGetWidth(pixelBuffer))")
//                    print("Pixel Buffer Height: \(CVPixelBufferGetHeight(pixelBuffer))")
//
//                    if let segmentedImage = self.convert(pixelBuffer: pixelBuffer) {
//                        self.segmentedImage = segmentedImage
//                        print("Segmentation successful, image updated.")
//                    } else {
//                        print("Error in converting image.")
//                    }
//                } else {
//                    print("No pixel buffer found in results.")
//                }
//            }
//            print("Performing request with handler")
//            try handler.perform([request])
//        } catch {
//            print("Failed to perform image segmentation: \(error)")
//        }
//    }
//    
    private func preprocessImage(cgImage: CGImage) -> CIImage? {
        let ciImage = CIImage(cgImage: cgImage)
        let size = CGSize(width: 513, height: 513) // Expected size for DeepLabV3
        
        let resizedCIImage = ciImage.resizeTo(size: size)
        print("Preprocessed image size: \(resizedCIImage?.extent.size ?? CGSize.zero)")
        return resizedCIImage
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

extension CIImage {
    func resizeTo(size: CGSize) -> CIImage? {
        let scaleX = size.width / extent.size.width
        let scaleY = size.height / extent.size.height
        return transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
    }
}


#Preview {
    ContentView()
}
