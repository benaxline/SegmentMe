//
//  choosePhoto.swift
//  SegmentMe
//
//  Created by Benjamin Axline on 6/21/24.
//

import SwiftUI
import PhotosUI

struct choosePhoto: View {
    @State private var pickerItems = [PhotosPickerItem]()
    @State private var selectedImages = [Image]()
    
    var body: some View {
        ScrollView {
            ForEach(0..<selectedImages.count, id: \.self) { i in
                selectedImages[i]
                    .resizable()
                    .scaledToFit()
            }
        }
            
        Spacer()
        
        PhotosPicker("Select Images",
                     selection: $pickerItems,
                     matching: .images)
        
        Spacer()
    }
}

#Preview {
    choosePhoto()
}
