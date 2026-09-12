//
//  ToneMapModifier.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/11/26.
//

import SwiftUI

/// Produces a tone mapping effect on the content view..
public struct ToneMapModifier: ViewModifier {
    /// EDR profile configuration.
    public let profile: Profile
    /// EDR headroom information for use with tone mapping.
    public let headroom: Headroom

    public func body(content: Content) -> some View {
        ZStack {
            if profile.options.isToneMapDefault, profile.mode != .sdr {
                content
                    // Apply default EDR tone mapping.
                    .layerEffect(
                        ShaderLibrary.bundle(Bundle.module).defaultToneMap(.float(headroom.current)),
                        maxSampleOffset: .zero
                    )
            } else {
                content
            }
        }
    }
}
