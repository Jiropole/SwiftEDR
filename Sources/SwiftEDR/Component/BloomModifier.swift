//
//  SwiftEDRBloom.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/1/26.
//

import SwiftUI

/// Produces a bloom effect on the content view..
public struct BloomModifier: ViewModifier {
    /// EDR profile configuration.
    public let profile: Profile

    public func body(content: Content) -> some View {
        ZStack {
            if profile.bloom.radius > 0, profile.bloom.intensity > 0 {
                ZStack {
                    // Layer the unmodified content.
                    content
                        .opacity(profile.options.isBloomHighlightsOnly ? 0.0 : 1.0)

                    // Extract a highlights layer from the content to be screened on top.
                    content
                        .modifier(HighlightsModifier(profile: profile))
                }
                // Screen highlights layer over content.
                .blendMode(.plusLighter)
            } else {
                content
                    .opacity(profile.options.isBloomHighlightsOnly ? 0.0 : 1.0)
            }
        }
    }
}
