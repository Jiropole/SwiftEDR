//
//  ToneMap.swift
//  SwiftEDR
//
//  The tone map curve: extended-range linear color into the range a display can show. This file is the reference definition; `defaultToneMap` in
//  Shaders.metal is its GPU twin, and renderers with their own shaders (such as the app's Metal renderer) mirror the same arithmetic.
//

import Foundation
import simd

/// Compresses extended-range linear light into a display's range, between two ways of doing it that `highlightBurn` blends.
///
/// At 0 the brightest channel is compressed by an identity-then-rational curve and all three channels are scaled by the same factor, which keeps hue and saturation
/// however bright the light is: a saturated color stays saturated at a lower level, and the picture is richer but dimmer.
/// At 1 each channel is compressed by that same curve on its own, as a display clips: an overbright saturated color's weaker channels catch up with its strongest and
/// it heads for white, while a cell with one low channel stays saturated beside its overbright neighbours. That is how bright light looks to the eye and to a camera, and it
/// gives glows a hot core instead of the same color at a lower level.
/// The shoulder's slope matches the identity at the knee, so both are smooth everywhere below the peak.
public struct ToneMap: BaseModel {
    /// Where the highlight shoulder begins, as a fraction of the ceiling. Colors whose brightest channel is below it are unchanged.
    /// Starting below 1 leaves room above the display's white for the shoulder without dimming the rest of the image.
    public var knee: Float = 0.75 {
        didSet { knee = min(max(knee, 0), 0.99) }
    }

    /// Linear intensity (in units of standard white) that maps to the ceiling; anything brighter is held there, hue intact.
    public var peak: Float = 4 {
        didSet { peak = max(peak, 1.01) }
    }

    /// How much of the compression is per channel, from 0 (hue and saturation are kept at any brightness) to 1 (each channel is compressed on its own, as a clip would
    /// have it, and bright light goes to white). In between is the blend of the two.
    public var highlightBurn: Float = ToneMap.defaultHighlightBurn {
        didSet { highlightBurn = min(max(highlightBurn, 0), 1) }
    }

    /// The default for EDR, which is shown in the standard range with the system's own clip as the look people expect: about half way to it.
    public static let defaultHighlightBurn: Float = 0.5

    /// The default for a mode. HDR leaves the highlight compression to the display, which does most of it, so a little burn goes a long way there.
    public static func defaultHighlightBurn(for mode: Profile.Mode) -> Float {
        mode == .hdr ? 0.2 : defaultHighlightBurn
    }

    public static let `default` = ToneMap()

    public init(knee: Float = 0.75, peak: Float = 4, highlightBurn: Float = ToneMap.defaultHighlightBurn) {
        self.knee = min(max(knee, 0), 0.99)
        self.peak = max(peak, 1.01)
        self.highlightBurn = min(max(highlightBurn, 0), 1)
    }

    /// The tone map a profile asks for: the default, with the profile's own burn if it has one, and its mode's default burn if not.
    public init(profile: Profile) {
        self.init()
        highlightBurn = profile.highlightBurn.map { Float($0) } ?? Self.defaultHighlightBurn(for: profile.mode)
    }

    /// Whether a display with `ceiling` (its brightest component value, 1 for a standard display) can show everything up to `peak` as it is,
    /// which leaves nothing to tone map.
    public func isIdentity(ceiling: Float) -> Bool { ceiling >= peak }

    /// Tone maps linear `color` for a display that can show component values up to `ceiling`. With a ceiling of 1 this is the renderer's curve.
    public func apply(to color: SIMD3<Float>, ceiling: Float = 1) -> SIMD3<Float> {
        let c = simd_max(color, .zero)
        let ceiling = max(ceiling, 1)
        guard !isIdentity(ceiling: ceiling) else { return c }
        let kneeLevel = knee * ceiling
        let m = max(c.x, c.y, c.z)
        guard m > kneeLevel else { return c }
        let hueKept = c * (shoulder(m, kneeLevel: kneeLevel, ceiling: ceiling) / m)
        guard highlightBurn > 0 else { return hueKept }
        let perChannel = SIMD3(shoulder(c.x, kneeLevel: kneeLevel, ceiling: ceiling),
                               shoulder(c.y, kneeLevel: kneeLevel, ceiling: ceiling),
                               shoulder(c.z, kneeLevel: kneeLevel, ceiling: ceiling))
        return hueKept + (perChannel - hueKept) * highlightBurn
    }

    /// One component compressed: unchanged up to the knee, then a rational curve that reaches the ceiling at the peak and is held there.
    private func shoulder(_ v: Float, kneeLevel: Float, ceiling: Float) -> Float {
        guard v > kneeLevel else { return v }
        let t = min(max((v - kneeLevel) / (peak - kneeLevel), 0), 1)
        let k = (ceiling - kneeLevel) / (peak - ceiling)
        return kneeLevel + (ceiling - kneeLevel) * t * (1 + k) / (t + k)
    }
}
