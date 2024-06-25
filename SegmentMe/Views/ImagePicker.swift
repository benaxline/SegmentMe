//
//  ImagePicker.swift
//  SegmentMe
//
//  Created by Benjamin Axline on 6/25/24.
//

import SwiftUI

struct ImagePicker: NSViewControllerRepresentable {
    @Binding var image: NSImage?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSViewController(context: Context) -> NSViewController {
        let viewController = NSViewController()
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.png, .jpeg]
        panel.begin { response in
            if response == .OK, let url = panel.url, let image = NSImage(contentsOf: url) {
                context.coordinator.parent.image = image
            }
        }
        return viewController
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) { }

    class Coordinator: NSObject {
        var parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }
    }
}

