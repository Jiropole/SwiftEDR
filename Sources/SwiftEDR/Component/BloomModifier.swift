//
//  SwiftEDRBloom.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/1/26.
//

import SwiftUI

/// Produces a bloom effect on the content view..

public struct BloomModifier: ViewModifier {
    /// EDR picture configuration.
    public let picture: Picture
    
    // Diagnostic options.
    public let options: Diagnostics

    public func body(content: Content) -> some View {
        ZStack {
            if picture.bloom.radius > 0, picture.bloom.intensity > 0 {
                // Extract a highlights layer from the content.
                content
                    .modifier(HighlightsModifier(picture: picture))
                
                // Layer the crisp foreground over the highlights.
                if !options.isBloomHighlightsOnly {
                    content
                }
            } else {
                content
            }
        }
    }
}
