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
    @State private var imageNames = [String]()
    @State private var selectedImage: NSImage?
    
    var body: some View {
        NavigationSplitView {
            List(images.indices, id: \.self) { index in
                HStack {
                    Image(nsImage: images[index])
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                        .onTapGesture {
                            selectedImage = images[index]
                    }
                    Spacer()
                    
                    Text("\(imageNames[index])")
                }
            }
            .navigationTitle("Your Photos")
            .frame(minWidth: 300)
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        importing = true
                    }){
                        Label("", systemImage: "square.and.arrow.down")
                    }
                    .padding()
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
                }
            }
        } detail: {
            if let selectedImage = selectedImage {
                Image(nsImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .navigationTitle("Photo Detail")
            } else {
                Spacer()
                Text("Select a Photo")
                    .font(.largeTitle)
                    .foregroundStyle(.gray)
                Spacer()
            }
        }
        
    }


    func putIntoNavSplit(from file: URL) {
        do {
            let data = try Data(contentsOf: file)
            if let nsImage = NSImage(data: data) {
                images.append(nsImage)
                imageNames.append(file.lastPathComponent)
            }
        } catch {
            print("Error loading image: \(error)")
        }
    }
}


#Preview {
    ImportingView()
}
