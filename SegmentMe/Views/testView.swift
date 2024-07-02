//
//  testView.swift
//  SegmentMe
//
//  Created by Benjamin Axline on 7/2/24.
//

import SwiftUI

struct testView: View {
    @State private var hoverLocation: CGPoint = .zero
    @State private var isHovering = false
    @State private var clickLocation: CGPoint = .zero
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.indigo)
                .frame(width: 400, height: 400)
                .onContinuousHover(perform: { phase in
                    switch phase {
                    case .active (let location):
                        hoverLocation = location
                        isHovering = true
                    case .ended:
                        isHovering = false
                    }
                })
                .overlay {
                    if isHovering {
                        Circle()
                            .fill(.white)
                            .opacity(0.5)
                            .frame(width: 30, height: 30)
                            .position(x: hoverLocation.x, y: hoverLocation.y)
                        //                    Text("x: \(hoverLocation.x), y: \(hoverLocation.y)")
                        //                        .foregroundStyle(.white)
                        //                        .font(.title)
                    }
                }
                .gesture(TapGesture().onEnded({
                    clickLocation = hoverLocation
                    print("gesture detected")
                    print("\(clickLocation)")
                }))
        }
    }
}

#Preview {
    testView()
}
