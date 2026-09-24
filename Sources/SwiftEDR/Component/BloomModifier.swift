//
//  SwiftEDRBloom.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/1/26.
//

import SwiftUI

/// Produces a bloom effect on the content view..
public struct BloomModifier: ViewModifier {
    
    @Environment(\.edrPalette) private var palette

    public func body(content: Content) -> some View {
        ZStack {
            // Layer the unmodified content.
            content
                .opacity(palette.profile.options.isBloomSolo ? 0.0 : 1.0)

            if palette.profile.isBloomEnabled {
                // Extract a highlights layer from the content to be screened on top.
                content
                    .modifier(HighlightsModifier())
                    .blendMode(.plusLighter)
            }
        }
    }
}
