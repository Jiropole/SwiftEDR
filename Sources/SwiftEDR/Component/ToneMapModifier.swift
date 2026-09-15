//
//  ToneMapModifier.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/11/26.
//

import SwiftUI

/// Produces a tone mapping effect on the content view..
public struct ToneMapModifier: ViewModifier {
    
    @Environment(\.edrPalette) private var palette

    public func body(content: Content) -> some View {
        ZStack {
            if palette.profile.options.isToneMapDefault, palette.profile.mode != .sdr {
                content
                    // Apply default EDR tone mapping.
                    .layerEffect(
                        ShaderLibrary.bundle(Bundle.module).defaultToneMap(.float(palette.headroom.current)),
                        maxSampleOffset: .zero
                    )
            } else {
                content
            }
        }
    }
}


