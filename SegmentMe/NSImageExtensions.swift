//
//  NSImageExtensions.swift
//  SegmentMe
//
//  Created by Benjamin Axline on 6/24/24.
//

import Cocoa

extension NSImage {
    func resized(withSize targetSize: NSSize) -> NSImage? {
        let frame = NSRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)
        guard let representation = self.bestRepresentation(for: frame, context: nil, hints: nil) else {
            return nil
        }
        let image = NSImage(size: targetSize, flipped: false, drawingHandler: { (_) -> Bool in
            return representation.draw(in: frame)
        })
        return image
    }
    
    func pixBuff() -> Data? {
        guard let tiffData = self.tiffRepresentation else { return nil }
        guard let bitmapRep = NSBitmapImageRep(data: tiffData) else { return nil }
        let pngData = bitmapRep.representation(using: .png, properties: [:])
        return pngData
    }
}
