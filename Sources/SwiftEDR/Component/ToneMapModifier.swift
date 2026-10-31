//
//  ToneMapModifier.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/11/26.
//

import SwiftUI

/// Tone maps the content into the standard range, when the profile asks for it (`Profile.Options.toneMapDefault`, on in the EDR defaults).
///
/// The curve is `ToneMap`. In EDR mode the content is by definition shown in the standard range, so it is always mapped there, which is also
/// what the app's Metal renderer does. In HDR mode the display is expected to show the extended range, so the content is only mapped on a display
/// with no headroom to show it, such as an external standard-range monitor, where the system would otherwise clip each channel and whiten the color.
/// A renderer that tone maps for itself should not be given a profile that asks for this.
public struct ToneMapModifier: ViewModifier {

    @Environment(\.edrPalette) private var palette

    public init() {}

    /// The tone map to apply for `palette`, or nil when the content should be left alone.
    public static func toneMap(for palette: Palette) -> ToneMap? {
        let profile = palette.profile
        guard profile.options.isToneMapDefault else { return nil }
        switch profile.mode {
        case .sdr:
            return nil
        case .edr:
            return ToneMap(profile: profile)
        case .hdr:
            // Within a hair of 1 counts as no headroom.
            return min(palette.headroom.potential, profile.maxHeadroom) <= 1.01 ? ToneMap(profile: profile) : nil
        }
    }

    public func body(content: Content) -> some View {
        if let toneMap = Self.toneMap(for: palette) {
            content
                .layerEffect(
                    ShaderLibrary.bundle(Bundle.module).defaultToneMap(
                        .float(toneMap.knee), .float(toneMap.peak), .float(toneMap.highlightBurn), .float(1)),
                    maxSampleOffset: .zero
                )
        } else {
            content
        }
    }
}
