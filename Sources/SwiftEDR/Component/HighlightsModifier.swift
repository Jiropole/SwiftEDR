//
//  SwiftEDRHighlights.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/1/26.
//

import SwiftUI

/// Extracts highlights from the content view, i.e. where luminosity exceeds threshold.
public struct HighlightsModifier: ViewModifier {

    static let downsampleFactor = 4.0

    @Environment(\.edrPalette) private var palette
    @State private var viewRadius: CGFloat = 20

    public func body(content: Content) -> some View {
        content
            // Extract bright areas according to bloom attributes.
            .layerEffect(highlightsShader, maxSampleOffset: .zero)

            // Downsample to reduce GPU overhead.
            .scaleEffect(1.0 / Self.downsampleFactor)

            // Blur the downsampled highlights.
            .blur(radius: palette.profile.bloom.radius * viewRadius / Self.downsampleFactor, opaque: false)

            // Restore original scale
            .scaleEffect(Self.downsampleFactor)

            // Keep viewRadius in sync.
            .onGeometryChange(for: CGSize.self, of: \.size) { viewSize in
                self.viewRadius = min(viewSize.width, viewSize.height)
            }
    }

    var highlightsShader: Shader {
        if palette.profile.bloom.mode == .luminance {
            return ShaderLibrary.bundle(Bundle.module).extractLuminanceOverbrights(
                .float(palette.effectiveBloomThreshold),
                .float(palette.profile.bloom.kneeWidth),
                .float(palette.profile.bloom.intensity)
            )
        } else {
            return ShaderLibrary.bundle(Bundle.module).extractComponentOverbrights(
                .float(palette.effectiveBloomThreshold),
                .float(palette.profile.bloom.kneeWidth),
                .float(palette.profile.bloom.intensity)
            )
        }
    }
}
