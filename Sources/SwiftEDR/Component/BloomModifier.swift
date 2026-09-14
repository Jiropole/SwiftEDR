//
//  SwiftEDRBloom.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/1/26.
//

import SwiftUI

/// Produces a bloom effect on the content view..
public struct BloomModifier: ViewModifier {
    
    @Environment(\.palette) private var palette

    public func body(content: Content) -> some View {
        ZStack {
            if palette.profile.bloom.radius > 0, palette.profile.bloom.intensity > 0 {
                ZStack {
                    // Layer the unmodified content.
                    content
                        .opacity(palette.profile.options.isBloomHighlightsOnly ? 0.0 : 1.0)

                    // Extract a highlights layer from the content to be screened on top.
                    content
                        .modifier(HighlightsModifier())
                        .blendMode(.plusLighter)
                }
            } else {
                content
                    .opacity(palette.profile.options.isBloomHighlightsOnly ? 0.0 : 1.0)
            }
        }
    }
}
