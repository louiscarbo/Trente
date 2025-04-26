//
//  ZoomableImageView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 26/04/2025.
//

import SwiftUI

struct ZoomableImageView: View {
    let uiImage: UIImage
    @Environment(\.presentationMode) private var presentationMode
    
    // the *accumulated* scale & offset
    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero
    // the *in-flight* gesture state
    @GestureState private var gestureScale: CGFloat = 1
    @GestureState private var gestureDrag: CGSize = .zero
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
            // combine accumulated + in-flight for smooth zoom
                .scaleEffect(scale * gestureScale)
            // combine accumulated + in-flight for pan
                .offset(
                    x: offset.width + gestureDrag.width,
                    y: offset.height + gestureDrag.height
                )
                .gesture(
                    // Pinch to zoom
                    MagnificationGesture()
                        .updating($gestureScale) { value, state, _ in
                            state = value
                        }
                        .onEnded { value in
                            scale *= value
                        }
                )
                .simultaneousGesture(
                    // Drag to pan
                    DragGesture()
                        .updating($gestureDrag) { value, state, _ in
                            state = value.translation
                        }
                        .onEnded { value in
                            offset.width += value.translation.width
                            offset.height += value.translation.height
                        }
                )
            
            // Dismiss button
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .padding()
                    .foregroundStyle(.thinMaterial)
            }
        }
    }
}
