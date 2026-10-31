//
//  ToneMapModifier.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/11/26.
//

import SwiftUI

/// Tone maps the content into the range the display can show, when the profile asks for it (`Profile.Options.toneMapDefault`).
///
/// The curve is `ToneMap`. The ceiling it compresses to is the display's potential headroom, limited by the profile: a color that asks for headroom
/// is shown as it is where the display can provide it, and only compressed where it can't, such as an external standard-range monitor, where the
/// system would otherwise clip each channel and whiten the color. A renderer that tone maps for itself should not set the option.
public struct ToneMapModifier: ViewModifier {

    @Environment(\.edrPalette) private var palette

    public init() {}

    /// The tone map to apply and the display's ceiling for it, or nil when the content should be left alone.
    public static func configuration(for palette: Palette) -> (toneMap: ToneMap, ceiling: Float)? {
        let profile = palette.profile
        guard profile.options.isToneMapDefault, profile.mode != .sdr else { return nil }
        let toneMap = ToneMap(profile: profile)
        let ceiling = Float(max(1, min(palette.headroom.potential, profile.maxHeadroom)))
        return toneMap.isIdentity(ceiling: ceiling) ? nil : (toneMap, ceiling)
    }

    public func body(content: Content) -> some View {
        if let (toneMap, ceiling) = Self.configuration(for: palette) {
            content
                .layerEffect(
                    ShaderLibrary.bundle(Bundle.module).defaultToneMap(
                        .float(toneMap.knee), .float(toneMap.peak), .float(toneMap.highlightBurn), .float(ceiling)),
                    maxSampleOffset: .zero
                )
        } else {
            content
        }
    }
}
