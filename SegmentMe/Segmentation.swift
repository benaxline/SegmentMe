//
//  segmentation.swift
//  SegmentMe
//
//  Created by Benjamin Axline on 6/24/24.
//

import PhotosUI
import CoreML
import CoreVideo


class Segmentation: DeepLabV3 {

    private let model: DeepLabV3
    
    init() throws {
        let config = MLModelConfiguration()
        self.model = try DeepLabV3(configuration: config)
    }
    
    func SegmentImage(image: CGImage?) {
        do {
            let input = try DeepLabV3Input(imageWith: image)
            let prediction = try model.prediction(input: input)
            let output = prediction.semanticPredictions
        }
        catch {
            error("Model not run.")
        }
    }
    
}
