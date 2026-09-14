//
//  SwiftEDRHighlights.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/1/26.
//

import SwiftUI

/// Extracts highlights from the content view, i.e. where luminosity exceeds threshold.
public struct HighlightsModifier: ViewModifier {

    @Environment(\.palette) private var palette
    @State private var viewRadius: CGFloat = 20

    public func body(content: Content) -> some View {
        content
            // Extract bright areas according to bloom attributes.
            .layerEffect(
                ShaderLibrary.bundle(Bundle.module).extractOverbrights(
                    .float(palette.effectiveBloomThreshold),
                    .float(palette.profile.bloom.kneeWidth),
                    .float(palette.profile.bloom.intensity)
                ),
                maxSampleOffset: .zero)

            // Downsample to reduce GPU overhead.
            .scaleEffect(0.25)

            // Blur the downsampled highlights.
            .blur(radius: palette.profile.bloom.radius * viewRadius / 4.0, opaque: false)

            // Restore original scale
            .scaleEffect(4.0)

            // Scale the intensity of blurred highlights.
            .colorMultiply(multiplierColor)

            // Keep viewRadius in sync.
            .onGeometryChange(for: CGSize.self, of: \.size) { viewSize in
                self.viewRadius = min(viewSize.width, viewSize.height)
            }
    }

    var multiplierColor: Color {
        palette.rgbColor([palette.profile.bloom.intensity,
                          palette.profile.bloom.intensity,
                          palette.profile.bloom.intensity, 1])
    }
}
