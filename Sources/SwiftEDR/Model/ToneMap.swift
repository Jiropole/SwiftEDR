//
//  ToneMap.swift
//  SwiftEDR
//
//  The tone map curve: extended-range linear color into the range a display can show. This file is the reference definition; `defaultToneMap` in
//  Shaders.metal is its GPU twin, and renderers with their own shaders (such as the app's Metal renderer) mirror the same arithmetic.
//

import Foundation
import simd

/// Compresses extended-range linear light into a display's range, keeping hue.
///
/// The brightest channel is compressed by an identity-then-rational curve and all three channels are scaled by the same factor. A per-channel
/// curve would instead push an overbright saturated color toward white as its weaker channels caught up, so that is added back on purpose and by
/// a chosen amount (`highlightBurn`): beyond the display's white, a color is pulled toward white by `1 - exp(-burn * (brightness - ceiling))`.
/// That is how bright light looks to the eye and to a camera, and it gives glows a hot core instead of the same color at a lower level.
/// The shoulder's slope matches the identity at the knee, so the curve is smooth everywhere below the peak.
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

    /// How quickly brightness beyond the display's white drains to white. At 0 hue and saturation are kept at any brightness; at 1.5 a color twice
    /// standard white is about three quarters of the way and one three times it is white for practical purposes.
    public var highlightBurn: Float = ToneMap.defaultHighlightBurn {
        didSet { highlightBurn = min(max(highlightBurn, 0), 8) }
    }

    /// A gentle default: a color twice standard white is about a quarter of the way to white, and one five times it about 70%.
    public static let defaultHighlightBurn: Float = 0.3

    public static let `default` = ToneMap()

    public init(knee: Float = 0.75, peak: Float = 4, highlightBurn: Float = ToneMap.defaultHighlightBurn) {
        self.knee = min(max(knee, 0), 0.99)
        self.peak = max(peak, 1.01)
        self.highlightBurn = min(max(highlightBurn, 0), 8)
    }

    /// The tone map a profile asks for: the default, with the profile's own burn if it has one.
    public init(profile: Profile) {
        self.init()
        if let burn = profile.highlightBurn { highlightBurn = Float(burn) }
    }

    /// Whether a display with `ceiling` (its brightest component value, 1 for a standard display) can show everything up to `peak` as it is,
    /// which leaves nothing to tone map.
    public func isIdentity(ceiling: Float) -> Bool { ceiling >= peak }

    /// Tone maps linear `color` for a display that can show component values up to `ceiling`. With a ceiling of 1 this is the renderer's curve.
    public func apply(to color: SIMD3<Float>, ceiling: Float = 1) -> SIMD3<Float> {
        var c = simd_max(color, .zero)
        let ceiling = max(ceiling, 1)
        guard !isIdentity(ceiling: ceiling) else { return c }
        let knee = knee * ceiling
        let m = max(c.x, c.y, c.z)
        guard m > knee else { return c }
        // Not below the ceiling: a negative amount would push the color away from white.
        let whitening = 1 - exp(-highlightBurn * max(m - ceiling, 0))
        c += (SIMD3(repeating: m) - c) * whitening
        let t = min(max((m - knee) / (peak - knee), 0), 1)
        let k = (ceiling - knee) / (peak - ceiling)
        let mapped = knee + (ceiling - knee) * t * (1 + k) / (t + k)
        return c * (mapped / m)
    }
}
