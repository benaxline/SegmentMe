import SwiftUI
import CoreML
import Vision
import UniformTypeIdentifiers

struct ImportingView: View {
    @State private var importing = false
    @State private var images = [NSImage]()
    @State private var imageNames = [String]()
    @State private var selectedImage: NSImage?
    @State private var combinedImage: NSImage?

    var body: some View {
        NavigationSplitView {
            List(images.indices, id: \.self) { index in
                HStack {
                    Image(nsImage: images[index])
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .cornerRadius(10)
                        .onTapGesture {
                            selectedImage = images[index]
                            combinedImage = nil // Clear the previous combined image
                            runModel(image: images[index])
                        }
                    Spacer()
                    Text("\(imageNames[index])")
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Your Photos")
            .frame(minWidth: 300)
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        importing = true
                    }){
                        Label("", systemImage: "square.and.arrow.down")
                    }
                    .fileImporter(
                        isPresented: $importing,
                        allowedContentTypes: [.image],
                        allowsMultipleSelection: true) { result in
                            switch result {
                            case .success(let files):
                                files.forEach { file in
                                    let access = file.startAccessingSecurityScopedResource()
                                    let img = NSImage(byReferencing: file.absoluteURL)
                                    
                                    if !access {
                                        return
                                    }
                                    
                                    putIntoNavSplit(from: file)
                                    
                                    file.stopAccessingSecurityScopedResource()
                                }
                            case .failure(let error):
                                print(error)
                            }
                        }
                }
            }
        } detail: {
            if let combinedImage = combinedImage {
                Image(nsImage: combinedImage)
                    .resizable()
                    .scaledToFit()
                    .navigationTitle("Photo Detail")
            } else if let selectedImage = selectedImage {
                Image(nsImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .navigationTitle("Photo Detail")
            } else {
                Spacer()
                Text("Select a Photo")
                    .font(.largeTitle)
                    .foregroundStyle(.gray)
                Spacer()
            }
        }
    }

    func putIntoNavSplit(from file: URL) {
        do {
            let data = try Data(contentsOf: file)
            if let nsImage = NSImage(data: data) {
                images.append(nsImage)
                imageNames.append(file.lastPathComponent)
            }
        } catch {
            print("Error loading image: \(error)")
        }
    }

    func runModel(image: NSImage) {
        guard let model = try? DeepLabV3(configuration: MLModelConfiguration()) else {
            print("Failed to load model")
            return
        }

        guard let pixelBuffer = preprocessImage(image) else {
            print("Failed to preprocess image")
            return
        }

        do {
            let visionModel = try VNCoreMLModel(for: model.model)
            let request = VNCoreMLRequest(model: visionModel) { (request, error) in
                if let results = request.results as? [VNCoreMLFeatureValueObservation],
                   let segmentationMap = results.first?.featureValue.multiArrayValue {
                    handleSegmentationMap(segmentationMap, originalImage: image)
                }
            }

            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            try handler.perform([request])
        } catch {
            print("Failed to create VNCoreMLModel: \(error)")
        }
    }

    func preprocessImage(_ image: NSImage) -> CVPixelBuffer? {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            return nil
        }

        let width = 513
        let height = 513
        let attributes: [NSObject: AnyObject] = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ]

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, attributes as CFDictionary, &pixelBuffer)

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(buffer)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData,
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                space: rgbColorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)

        guard let cgImage = bitmapImage.cgImage else {
            CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
            return nil
        }

        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))

        return buffer
    }

    func handleSegmentationMap(_ segmentationMap: MLMultiArray, originalImage: NSImage) {
        let width = segmentationMap.shape[1].intValue
        let height = segmentationMap.shape[2].intValue

        var pixelData = [UInt8](repeating: 0, count: width * height * 4)

        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = y * width + x
                let label = segmentationMap[[0, x as NSNumber, y as NSNumber]].intValue
                
                let color: (UInt8, UInt8, UInt8)
                switch label {
                case 0:
                    color = (0, 0, 0) // Background
                default:
                    color = (255, 0, 0) // Other classes
                }
                
                pixelData[4 * pixelIndex] = color.0
                pixelData[4 * pixelIndex + 1] = color.1
                pixelData[4 * pixelIndex + 2] = color.2
                pixelData[4 * pixelIndex + 3] = 128 // Semi-transparent
            }
        }

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: &pixelData,
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: width * 4,
                                space: rgbColorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        if let cgImage = context?.makeImage() {
            let overlayImage = NSImage(cgImage: cgImage, size: NSSize(width: width, height: height))
            DispatchQueue.main.async {
                combinedImage = combineImages(background: originalImage, overlay: overlayImage)
            }
        }
    }

    func combineImages(background: NSImage, overlay: NSImage) -> NSImage? {
        let newImage = NSImage(size: background.size)
        newImage.lockFocus()
        
        let backgroundRect = NSRect(origin: .zero, size: background.size)
        background.draw(in: backgroundRect)
        
        let overlayRect = NSRect(x: 0, y: 0, width: background.size.width, height: background.size.height)
        overlay.draw(in: overlayRect, from: NSRect(origin: .zero, size: overlay.size), operation: .sourceOver, fraction: 0.5)
        
        newImage.unlockFocus()
        return newImage
    }
}

#Preview {
    ImportingView()
}
