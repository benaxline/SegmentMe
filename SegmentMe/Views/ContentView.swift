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
    @State private var inputImage: CGImage?
    @State private var segmentedImage: CGImage?
    
    var body: some View {
//        ScrollView {
            VStack {
                HStack {
                    ZStack {
                        if let inputImage = inputImage {
                            Image(inputImage, scale: 1, label: Text("Input Image"))
                                .resizable()
                                .scaledToFit()
                                .frame(height: 400)
                                .padding()
                        } else {
                            Text("Select an Image")
                                .frame(height: 400)
                                .padding()
                        }
                        
                        if let segmentedImage = segmentedImage {
                            Image(segmentedImage, scale: 1, label: Text("Segmented Image"))
                                .resizable()
                                .scaledToFit()
                                .frame(height: 400)
                                .padding()
                        }
                    }
                }
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        inputImage = nil
                        segmentedImage = nil
                        selectImage()
                    }, label: {
                        Text("Select Image")
                    })
                    .padding()
                    .controlSize(.extraLarge)
                    
                    
                    Button(action: {
                        if let inputImage = inputImage{
                            segmentImage(image: inputImage)
                        }
                    }, label: {
                        Text("Segment Image")
                    })
                    .padding()
                    .controlSize(.extraLarge)
                    .disabled(inputImage == nil)
                    
                    Spacer()
            }
        }
        
    }
    
    private func selectImage() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.png, .jpeg, .heic]
        
        panel.begin { response in
            if response == .OK, let url = panel.url, let image = NSImage(contentsOf: url) {
                var rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
                self.inputImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil)
            }
        }
    }
    
    
    private func segmentImage(image: CGImage) {
        // load model
        guard let model = try? DeepLabV3(configuration: MLModelConfiguration()) else {
            print("model not created")
            return
        }
        var request: VNCoreMLRequest?
        
        // setup model
        if let visionModel = try? VNCoreMLModel(for: model.model) {
            request = VNCoreMLRequest(model: visionModel/*, completionHandler: visionRequestDidComplete*/)
            request?.imageCropAndScaleOption = .scaleFit
        } else {
            fatalError()
        }
        
        guard let input = try? DeepLabV3Input(imageWith: image) else {
            print("fail: input preparation")
            return
        }
        
        
        // pass input through model
        guard let prediction = try? model.prediction(input: input) else {
            print("fail: predition")
            return
        }
        
        
        let multiArray = prediction.semanticPredictions
//        let output = DeepLabV3Output(semanticPredictions: multiArray)
//        let buff = output.semanticPredictions.pixelBuffer
//        let temp = multiArray.cgImage(channel: 3)
        let segImage = multiArray.cgImage(min: 0, max: 20, channel: 3)
        
        let overlayImage = overlayImages(image: image, segmentation: segImage!, alpha: 0.3)
        self.segmentedImage = overlayImage
    }
    
    // function to overlay segmentation and original image
    private func overlayImages(image: CGImage, segmentation: CGImage, alpha: CGFloat) -> CGImage? {
        let width = image.width
        let height = image.height
        
        guard let context = CGContext(data: nil,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: image.bitsPerComponent,
                                      bytesPerRow: 0,
                                      space: image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!,
                                      bitmapInfo: image.bitmapInfo.rawValue) else {
            return nil
        }
        
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        context.setAlpha(alpha)
        
        context.draw(segmentation, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        let overlay = context.makeImage()
        return overlay
    }
    
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
