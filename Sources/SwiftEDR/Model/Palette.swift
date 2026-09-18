//
//  ProfileContext.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/14/26.
//

import SwiftUI

/// Wraps all EDR state into a single object that serves as the authoritative Color vendor.
public struct Palette: BaseModel {
    public var profile: Profile
    public var headroom: Headroom

    public init(profile: Profile, headroom: Headroom) {
        self.profile = profile
        self.headroom = headroom
    }

    public static let `default`: Palette = .init(profile: .Defaults.edr, headroom: .init())

    /// Used by bloom effect; takes adaptivity and current headroom into account.
    public var effectiveBloomThreshold: CGFloat {
        guard profile.mode == .hdr else { return profile.bloom.threshold }
        return profile.bloom.threshold + (headroom.current - 1) * profile.bloom.adaptivity
    }
}

// MARK: Color Factory

extension Palette {
    /// Profile correct color from HSVA `components`, with optional `boost`, normally used to push into EDR headroom.
    public func hsvColor(_ components: [CGFloat], boost: CGFloat = 1.0) -> Color {
        hsvColor(components, space: profile.colorSpace, boost: boost)
    }

    /// Profile correct color from HSVA `components`, with optional `boost`, normally used to push into EDR headroom.
    public func hsvColors(_ colors: [[CGFloat]], boost: CGFloat = 1.0) -> [Color] {
        let space = profile.colorSpace
        return colors.map { hsvColor($0, space: space, boost: boost) }
    }

    /// Profile correct color from RGBA `components`, with optional `boost`, normally used to push into EDR headroom.
    public func rgbColor(_ components: [CGFloat], boost: CGFloat = 1.0) -> Color {
        rgbColor(components, space: profile.colorSpace, boost: boost)
    }

    /// Profile correct color from RGBA `components`, with optional `boost`, normally used to push into EDR headroom.
    public func rgbColors(_ colors: [[CGFloat]], boost: CGFloat = 1.0) -> [Color] {
        let space = profile.colorSpace
        return colors.map { rgbColor($0, space: space, boost: boost) }
    }
}

private extension Palette {
    /// Create a color from HSVA components that is calibrated for the color space and headroom.
    func hsvColor(_ components: [CGFloat], space: CGColorSpace, boost: CGFloat = 1.0) -> Color {
        let p3Color = NativeColor(hue: components[0],
                                  saturation: components[1],
                                  brightness: components[2],
                                  alpha: components[3])
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        p3Color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return rgbColor([r, g, b, a], space: space, boost: boost)
    }

    /// Create a color from RGBA components that is calibrated for the color space and headroom.
    func rgbColor(_ components: [CGFloat], space: CGColorSpace, boost: CGFloat = 1.0) -> Color {
        var components = components.prefix(3).map({ $0 * boost }) + [components[3]]
        components = (profile.options.isLinearColorSpace || profile.mode == .sdr
                      ? components
                      : Self.nonlinearP3Components(components))
        guard let cgColor = CGColor(colorSpace: space, components: components) else {
            return Color(.displayP3, red: components[0], green: components[1],
                         blue: components[2], opacity: components[3])
        }
        return Color(cgColor: cgColor)
            .headroom(headroom.potential)
    }

    /// Experimental reintroduction of perceptual tonality to linear magnitude components.
    static func nonlinearP3Components(_ components: [CGFloat]) -> [CGFloat] {
        components.prefix(3).map({ extendedGammaToLinear($0) }) + [components[3]]
    }

    /// Inverse sRGB gamma.
    static func extendedGammaToLinear(_ extendedComponent: CGFloat) -> CGFloat {
        guard extendedComponent < 1.0 else { return extendedComponent }
        let absVal = abs(extendedComponent)
        let linearVal: CGFloat

        // Inverse sRGB/P3 transfer curve
        if absVal <= 0.04045 {
            linearVal = absVal / 12.92
        } else {
            linearVal = pow((absVal + 0.055) / 1.055, 2.4)
        }

        // Maintain the original sign to support extended darks/brights
        return extendedComponent >= 0 ? linearVal : -linearVal
    }
}
