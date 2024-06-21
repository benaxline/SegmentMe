//
//  ContentView.swift
//  SegmentMe
//
//  Created by Benjamin Axline on 6/20/24.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var pickerItems = [PhotosPickerItem]()
    @State private var selectedImages = [Image]()
    
    var body: some View {
        
        VStack {
            Spacer()
            ScrollView {
                ForEach(0..<selectedImages.count, id: \.self) { i in
                    selectedImages[i]
                        .resizable()
                        .scaledToFit()
                }
            }
                
            
            PhotosPicker("Select Images",
                         selection: $pickerItems,
                         matching: .images)
            
            Spacer()
        }
        .onChange(of: pickerItems) {
            Task {
                selectedImages.removeAll()
                
                for item in pickerItems {
                    if let loadedImage = try await item.loadTransferable(type: Image.self) {
                        selectedImages.append(loadedImage)
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 500)
    }
}



#Preview {
    ContentView()
}
