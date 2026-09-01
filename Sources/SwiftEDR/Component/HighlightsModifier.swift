//
//  SwiftEDRHighlights.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/1/26.
//

import SwiftUI

/// Extracts highlights from the content view, i.e. where luminosity exceeds threshold.

public struct HighlightsModifier: ViewModifier {
    /// EDR profile configuration.
    public let profile: Profile

    @State private var viewRadius: CGFloat = 20

    public func body(content: Content) -> some View {
        content
            .layerEffect(
                ShaderLibrary.bundle(Bundle.module).extractOverbrights(
                    .float(profile.bloom.threshold),
                    .float(profile.bloom.kneeWidth),
                    .float(profile.bloom.intensity)
                ),
                maxSampleOffset: .zero)
            // Downsample to reduce GPU overhead.
            .scaleEffect(0.25)
            // Blur the downsampled highlights.
            .blur(radius: profile.bloom.radius * viewRadius / 4.0, opaque: false)
            // Restore original scale
            .scaleEffect(4.0)
            // Apply intensity to the blurred highlights.
            .colorMultiply(Color(.displayP3,
                                 red: profile.bloom.intensity,
                                 green: profile.bloom.intensity,
                                 blue: profile.bloom.intensity))
            .onGeometryChange(for: CGSize.self, of: \.size) { viewSize in
                self.viewRadius = min(viewSize.width, viewSize.height)
            }
    }
}
