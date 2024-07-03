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
    @State private var wantedSegmentation: CGImage?
    @State private var isHovering = false
    @State private var hoverLocation: CGPoint = .zero
    @State private var clickLocation: CGPoint = .zero
    
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
                                .onContinuousHover(perform: { phase in
                                    switch phase {
                                    case .active (let location):
                                        hoverLocation = location
                                        isHovering = true
                                    case .ended:
                                        isHovering = false
                                    }
                                })
                                .gesture(TapGesture().onEnded({
                                    print("event detected")
                                    clickLocation = hoverLocation
                                    segmentImage(image: inputImage)
//                                    getNearestMaskVal(maskSegmentation: self.segmentedImage)
                                    
                                }))
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
                if isHovering {
                    Text("Hover Location: \(hoverLocation)")
                    Text("Click Location: \(clickLocation)")
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
                    
                    
//                    Button(action: {
//                        if let inputImage = inputImage{
//                            segmentImage(image: inputImage)
//                        }
//                    }, label: {
//                        Text("Segment Image")
//                    })
//                    .padding()
//                    .controlSize(.extraLarge)
//                    .disabled(inputImage == nil)
                    
                    Spacer()
            }
        }
        
    }
    
    private func getNearestMaskVal(maskSegmentation: MLMultiArray) {
        // rounded coordinates
        let x = self.clickLocation.x.rounded()
        let y = self.clickLocation.y.rounded()
        
        let most = 20
        let least = 0
        
        // get click value
//        print(maskSegmentation.dataType == .double)
        let yStride = maskSegmentation.strides[0].intValue
        let xStride = maskSegmentation.strides[1].intValue
//        print("xStride: \(xStride), yStride: \(yStride)")
        let width = maskSegmentation.shape[0].intValue
        let height = maskSegmentation.shape[1].intValue

        let ptr = UnsafeMutablePointer<Int32>(OpaquePointer(maskSegmentation.dataPointer))
        
        
        let wantedValue = ptr[Int(x) * xStride + Int(y) * yStride]
        print(wantedValue)
        
        
        var pixels = [UInt8](repeating: 0, count: (width * height) )
        
//        let scaled = (value - most) * T(255) / (most - least)
        for i in 0..<width {
            for j in 0..<height {
                let value = ptr[Int(i) * xStride + Int(j) * yStride]
//                print(value)
                if value == wantedValue {
                    // save it
                    let scaled = (Int(value) - least) * 255 / (most - least)
                    let pixel = clamp(scaled, min: 0, max: 255)
                    pixels[j*width + i] = UInt8(pixel) // might not be right: row * stride * j + i
                }
                else {
                    
                    pixels[j*width + i] = .zero
                }
            }
        }
        
        self.wantedSegmentation = CGImage.fromByteArrayGray(pixels, width: width, height: height)
        
//
//        let value = ptr[y*yStride + x*xStride]
//        let scaled = (value - min) * T(255) / (max - min)
//        let pixel = clamp(scaled, min: T(0), max: T(255)).toUInt8
                    
                
            
        
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
        
//        let overlayImage = overlayImages(image: image, segmentation: segImage!, alpha: 0.5)
//        self.segmentedImage = overlayImage
        getNearestMaskVal(maskSegmentation: multiArray)
        
        let overlayImage = overlayImages(image: image, segmentation: self.wantedSegmentation!, alpha: 0.5)
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
