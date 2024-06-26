//
//  NSImage+PixelBuffer.swift
//  SegmentMe
//
//  Created by Benjamin Axline on 6/25/24.
//

import Cocoa
import CoreVideo

extension NSImage {
    convenience init?(pixelBuffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue),
              let cgImage = context.makeImage() else { return nil }

        self.init(cgImage: cgImage, size: NSSize(width: width, height: height))
    }
    
    func resize(newSize: NSSize) -> NSImage {
        let aspectRatio = self.size.width / self.size.height
        var scaledSize = newSize
        
        if newSize.width / newSize.height > aspectRatio {
            scaledSize.width = newSize.height * aspectRatio
        } else {
            scaledSize.height = newSize.width / aspectRatio
        }
        
        let newImage = NSImage(size: scaledSize)
        newImage.lockFocus()
        let ctx = NSGraphicsContext.current
        ctx?.imageInterpolation = .high
        self.draw(in: NSRect(origin: .zero, size: scaledSize),
                  from: NSRect(origin: .zero, size: self.size),
                  operation: .sourceOver,
                  fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }
}
