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
        
            ImportingView()
        }
        .frame(minWidth: 500, minHeight: 500)
    }
}



#Preview {
    ContentView()
}
