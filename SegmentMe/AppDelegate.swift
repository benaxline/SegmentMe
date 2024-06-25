////
////  AppDelegate.swift
////  SegmentMe
////
////  Created by Benjamin Axline on 6/25/24.
////
//
//import Cocoa
//import CoreML
//import Vision
//import UniformTypeIdentifiers
//import SwiftUI
//
////@main
////class AppDelegate: NSObject {
//    
//   
//class AppDelegate {
//    @State private var combinedImage: NSImage?
//    
//    func openImage() {
//        let dialog = NSOpenPanel()
//        dialog.title = "Choose an Image"
//        dialog.allowedContentTypes = [.jpeg, .png]
//        
//        if dialog.runModal() == NSApplication.ModalResponse.OK {
//            if let result = dialog.url {
//                let image = NSImage(contentsOf: result)
//                runModel(image: image!)
//            }
//        }
//    }
//    
//    func runModel(image: NSImage) {
//        guard let model = try? DeepLabV3(configuration: MLModelConfiguration()) else {
//            print("failed to run model")
//            return
//        }
//        
//        guard let pixelBuffer = preprocessing(image: image) else {
//            print("failed to build pixel buffer")
//            return
//        }
//        
//        do {
//            let visionModel = try VNCoreMLModel(for: model.model)
//            let req = VNCoreMLRequest(model: visionModel) { (req, error) in
//                if let results = req.results as? [VNCoreMLFeatureValueObservation],
//                   let segmentationMap = results.first?.featureValue.multiArrayValue {
//                    self.handleSegmentationMap(segmentationMap: segmentationMap, image: image)
//                }
//            }
//            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
//            try? handler.perform([req])
//        } catch {
//            print("error in model creationg: \(error)")
//        }
//        
//    }
//    
//    func preprocessing(image: NSImage) -> CVPixelBuffer? {
//        // convert NSImage to CVPixelBuffer
//        guard let tiffData = image.tiffRepresentation,
//              let bitMap = NSBitmapImageRep(data: tiffData) else {
//            return nil
//        }
//        
//        // w and h we need to get to
//        let width = 513
//        let height = 513
//        
//        let attributes: [NSObject: AnyObject] = [
//            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
//            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue ]
//        
//        var pixelBuffer: CVPixelBuffer?
//        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, attributes as CFDictionary, &pixelBuffer)
//        
//        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
//            return nil
//        }
//        
//        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
//        let pixelData = CVPixelBufferGetBaseAddress(buffer)
//        
//        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
//        let context = CGContext(data: pixelData,
//                                width: width,
//                                height: height,
//                                bitsPerComponent: 8,
//                                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
//                                space: rgbColorSpace,
//                                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
//        
//        guard let cgImage = bitMap.cgImage else {
//            CVPixelBufferUnlockBaseAddress(buffer,
//                                           CVPixelBufferLockFlags(rawValue: 0))
//            return nil
//        }
//        
//        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
//        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
//        
//        return buffer
//        
//    }
//    
//    func handleSegmentationMap(segmentationMap: MLMultiArray, image: NSImage) -> NSImage? {
//        // overlays segmentation map and photo
//        let width = segmentationMap.shape[1].intValue
//        let height = segmentationMap.shape[2].intValue
//        var pixelData = [UInt8](repeating: 0, count: width*height*4)
//        
//        for y in 0..<height {
//            for x in 0..<width {
//                let pixelIndex = y*width + x
//                let label = segmentationMap[[0, x as NSNumber, y as NSNumber]].intValue
//                
//                let color: (UInt8, UInt8, UInt8)
//                switch label {
//                case 0:
//                    color = (0, 0, 0)
//                default:
//                    color = (255, 0, 0)
//                }
//                
//                pixelData[4 * pixelIndex] = color.0
//                pixelData[4 * pixelIndex + 1] = color.1
//                pixelData[4 * pixelIndex + 2] = color.2
//                pixelData[4 * pixelIndex + 3] = 128
//            }
//        }
//        
//        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
//        let context = CGContext(data: &pixelData,
//                                width: width,
//                                height: height,
//                                bitsPerComponent: 8,
//                                bytesPerRow: width * 4,
//                                space: rgbColorSpace,
//                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
//        
//        if let cgImage = context?.makeImage() {
//            let overlay = NSImage(cgImage: cgImage, size: NSSize(width: width, height: height))
//            DispatchQueue.main.async {
//                $combinedImage = combinedImages(background: image, overlay: overlay)
//            }
//            return combined
//        }
//        else{
//            return nil
//            
//        }
//        
//    }
//    
//    func combineImages(background: NSImage, overlay: NSImage) -> NSImage{
//        // combine mask and background
//        let newImg = NSImage(size: background.size)
//        newImg.lockFocus()
//        
//        let backgroundRect = NSRect(origin: .zero, size: background.size)
//        background.draw(in: backgroundRect)
//        
//        let overlayRect = NSRect(x: 0,
//                                 y: 0,
//                                 width: background.size.width,
//                                 height: background.size.height)
//        overlay.draw(in: overlayRect,
//                     from: NSRect(origin: .zero, size: overlay.size),
//                     operation: .sourceOver,
//                     fraction: 0.5)
//        
//        newImg.unlockFocus()
//        return newImg
//    }
//    
//}
