//
//  segImage.swift
//  SegmentMe
//
//  Created by Benjamin Axline on 6/28/24.
//

import Foundation
import CoreML
import Vision
import PhotosUI



class segImage {
    
    static func createDeepLabModel() -> VNCoreMLModel {
        let config = MLModelConfiguration()
        
        let deeplabWrapper = try? DeepLabV3(configuration: config)
        
        guard let deeplab = deeplabWrapper else {
            fatalError("failed to create model instance")
        }
        
        let deeplabModel = deeplab.model
        
        guard let deeplabVisionModel = try? VNCoreMLModel(for: deeplabModel) else {
            fatalError("failed to create vision model instance")
        }
        
        return deeplabVisionModel
    }
    
    private static let deepLab = createDeepLabModel()
    
    struct Prediction {
        // output: multiarray
        let mask: MLMultiArray
    }
    
    typealias deeplabHandler = (_ predictions: [Prediction]?) -> Void
    
    private var handlers = [VNRequest: deeplabHandler]()
    
    private func createDeeplabRequest() -> VNImageBasedRequest {
        let imageRequest = VNCoreMLRequest(model: segImage.deepLab,
                                           completionHandler: visionRequestHandler)
        
        imageRequest.imageCropAndScaleOption = .scaleFit
        return imageRequest
    }
    
    func makeMasks( for image: NSImage, completionHandler: @escaping deeplabHandler) throws {
        // turn to CGImage
        var rec = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        guard let cgImage = image.cgImage(forProposedRect: &rec, context: nil, hints: nil) else{
            fatalError("failed to create CGImage")
        }
        
        let request = createDeeplabRequest()
        handlers[request] = completionHandler
        
        let handler = VNImageRequestHandler(cgImage: cgImage)
        let requests: [VNRequest] = [request]
        
        try handler.perform(requests)
    }
    
    private func visionRequestHandler(_ request: VNRequest, error: Error?) {
        guard let handler = handlers.removeValue(forKey: request) else {
            fatalError("every request must have handler")
        }
        
        var predictions: [Prediction]? = nil
//        
//        defer {
//            handlers(predictions)
//        }
//        
        if let error = error {
            print("ERROR: \(error.localizedDescription)")
            return
        }
        
        if request.results == nil {
            print("No results!")
            return
        }
        
        guard let observations = request.results as? [VNClassificationObservation] else {
            print("wrong result type: \(type(of: request.results)).")
            return
        }
        
//        predictions = observations.map { observation in
//            Prediction(mask: observation.)
//        }
    }
    
}
