//
//  EDRModifier.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 8/31/26.
//

import SwiftUI

/// Applies EDR (extended dynamic range) color precision and display to the view content.

public struct EDRModifier: ViewModifier {
    /// EDR profile configuration.
    public let profile: Profile

    public init(profile: Profile) {
        self.profile = profile
    }

    public func body(content: Content) -> some View {
        Group {
            switch profile.mode {
            case .hdr:
                // Expand the allowed dynamic range for HDR.
                toneMapped(content: content)
                    .allowedDynamicRange(profile.relativeDynamicRange)
            default:
                // Other modes can still be tone mapped.
                toneMapped(content: content)
            }
        }
        .environment(\.profile, profile)
    }

    public func toneMapped(content: Content) -> some View {
        content
            .modifier(BloomModifier(profile: profile))
            .layerEffect(
                // Apply tone mapping
                ShaderLibrary.bundle(Bundle.module).cinematicToneMap(),
                maxSampleOffset: .zero
            )
    }
}
