//
//  segmentation.swift
//  SegmentMe
//
//  Created by Benjamin Axline on 6/24/24.
//

import PhotosUI
import CoreML


class segmentation: DeepLabV3 {

    private func segmentImage(image: NSImage?) {
        // resize to 513 x 513
        let resized = image?.resized(withSize: CGSize(width: 513, height: 513))
        
//        let buffer = resized?
        
        
    }
    
}
