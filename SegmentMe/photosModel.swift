//
//  photosModel.swift
//  SegmentMe
//
//  Created by Benjamin Axline on 6/21/24.
//

import Foundation
import SwiftUI

struct photo: Hashable, Codable {
    private var name: String
    var image: Image {
        Image(name)
    }
}
