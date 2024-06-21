//
//  ImportingView.swift
//  SegmentMe
//
//  Created by Benjamin Axline on 6/21/24.
//

import SwiftUI

struct ImportingView: View {
    @State private var importing = false
    @State private var images = [NSImage]()
    @State private var selectedImage: NSImage?
    
    var body: some View {
        NavigationSplitView {
            List(images.indices, id: \.self) { index in
                Image(nsImage: images[index])
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .onTapGesture {
                        selectedImage = images[index]
                    }
            }
            .navigationTitle("Your Photos")
        } detail: {
            if let selectedImage = selectedImage {
                Image(nsImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .navigationTitle("Photo Detail")
            } else {
                Text("Select a Photo")
                    .font(.largeTitle)
                    .foregroundStyle(.gray)
            }
        }
        
        Button("Import Photos", systemImage: "square.and.arrow.up") {
            importing = true
        }
        .fileImporter(
            isPresented: $importing,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true) {
                result in
                switch result {
                case .success(let files):
                    files.forEach { file in
                        // gain access
                        let access = file.startAccessingSecurityScopedResource()
                        
                        // if we don't have access
                        if !access {
                            return
                        }
                        
                        // put into nav split
                        putIntoNavSplit(from: file)
                        
                        // release access
                        file.stopAccessingSecurityScopedResource()
                    }
                case .failure(let error):
                    print(error)
                }
            }
//            .onChange(of: <#T##Equatable#>, <#T##action: (Equatable, Equatable) -> Void##(Equatable, Equatable) -> Void##(_ oldValue: Equatable, _ newValue: Equatable) -> Void#>)
            .buttonStyle(.bordered)
        
            
    }
//        .frame(minWidth: 500, minHeight: 500)
    func putIntoNavSplit(from file: URL) {
        do {
            let data = try Data(contentsOf: file)
            if let nsImage = NSImage(data: data) {
                images.append(nsImage)
            }
        } catch {
            print("Error loading image: \(error)")
        }
    }
}


#Preview {
    ImportingView()
}
