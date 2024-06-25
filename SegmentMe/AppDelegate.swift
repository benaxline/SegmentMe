//
//  AppDelegate.swift
//  SegmentMe
//
//  Created by Benjamin Axline on 6/25/24.
//

import Cocoa
import CoreML
import Vision
import UniformTypeIdentifiers

//@main
class AppDelegate: NSObject {
    
    
    
    @objc func openImage() {
        let dialog = NSOpenPanel()
        dialog.title = "Choose an Image"
        dialog.allowedContentTypes = [.jpeg, .png]
        
        if dialog.runModal() == NSApplication.ModalResponse.OK {
            if let result = dialog.url {
                let image = NSImage(contentsOf: result)
                runModel(image: image!)
            }
        }
    }
    
    func runModel(image: NSImage) {
        guard let model = try? DeepLabV3(configuration: MLModelConfiguration()) else { return }
        
        guard let pixelBuffer = preprocessing(image: image) else { return }
        
        do {
            let visionModel = try VNCoreMLModel(for: model.model)
            let req = VNCoreMLRequest(model: visionModel) { (req, error) in
                if let results = req.results as? [VNCoreMLFeatureValueObservation],
                   let segmentationMap = results.first?.featureValue.multiArrayValue {
                    self.handleSegmentationMap(segmentationMap: segmentationMap)
                }
            }
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            try? handler.perform([req])
        } catch {
            print("error in model creationg: \(error)")
        }
        
    }
    
    func processing(image: NSImage) -> CVPixelBuffer? {
        // convert NSImage to CVPixelBuffer
        guard let tiffData = image.tiffRepresentation,
              let bitMap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        
        // w and h we need to get to
        let width = 513
        let height = 513
        
        let attributes: [NSObject: AnyObject] = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue ]
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, attributes as CFDictionary, &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        
        let rgb
        
    }
    
    func handleSegmentationMap(segmentationMap: MLMultiArray) {
        // overlays segmentation map and photo
        }
    
}
