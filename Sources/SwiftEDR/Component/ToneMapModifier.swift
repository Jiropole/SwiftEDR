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
                    .background(alignment: .topLeading) {
                        // Layer or color effects appear to break the chain of EDR metadata.
                        // Therefore, we must remind the system we do want the headroom.
                        if profile.mode == .hdr {
                            profile
                                .rgbColor([0, 0, 0, 0.01])
                                .headroom(headroom.potential)
                                .frame(width: 0.25, height: 0.25)
                        }
                    }
            } else {
                content
            }
        }
    }
}
