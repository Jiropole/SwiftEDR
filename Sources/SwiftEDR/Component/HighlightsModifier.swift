//
//  SwiftEDRHighlights.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/1/26.
//

import SwiftUI

/// Extracts highlights from the content view, i.e. where luminosity exceeds threshold.

public struct HighlightsModifier: ViewModifier {
    /// EDR picture configuration.
    public let picture: Picture

    @State private var viewRadius: CGFloat = 20

    public func body(content: Content) -> some View {
        content
            .layerEffect(
                ShaderLibrary.bundle(Bundle.module).extractOverbrights(
                    .float(picture.bloom.threshold),
                    .float(picture.bloom.kneeWidth),
                    .float(picture.bloom.intensity)
                ),
                maxSampleOffset: .zero)
            // Downsample to reduce GPU overhead.
            .scaleEffect(0.25)
            // Blur the downsampled highlights.
            .blur(radius: picture.bloom.radius * viewRadius / 4.0, opaque: false)
            // Restore original scale
            .scaleEffect(4.0)
            // Apply intensity to the blurred highlights.
            .colorMultiply(Color(.displayP3,
                                 red: picture.bloom.intensity,
                                 green: picture.bloom.intensity,
                                 blue: picture.bloom.intensity))
            .onGeometryChange(for: CGSize.self, of: \.size) { viewSize in
                self.viewRadius = min(viewSize.width, viewSize.height)
            }
    }
}
