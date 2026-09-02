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
    
    // Diagnostic options.
    public let options: Diagnostics

    public func body(content: Content) -> some View {
        ZStack {
            if profile.bloom.radius > 0, profile.bloom.intensity > 0 {
                ZStack {
                    // Layer the crisp foreground over the highlights.
                    if !options.isBloomHighlightsOnly {
                        content
                    }
                    // Extract a highlights layer from the content.
                    content
                        .modifier(HighlightsModifier(profile: profile))
                }
                .blendMode(.screen)
            } else {
                content
            }
        }
    }
}
