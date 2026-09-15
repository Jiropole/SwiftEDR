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

    // Used by bloom effect; takes adaptivity and current headroom into account.
    public var effectiveBloomThreshold: CGFloat {
        guard profile.mode == .hdr else { return profile.bloom.threshold }
        return profile.bloom.threshold + (headroom.current - 1) * profile.bloom.adaptivity
    }
}

// MARK: Color Convenience

extension Palette {
    /// Convenience function to get a color space appropriate color from RGBA components.
    public func rgbColor(_ components: [CGFloat]) -> Color {
        Self.rgbColor(components, space: profile.mode.colorSpace, headroom: headroom)
    }

    /// Convenience function to get a color space appropriate color from HSVA components.
    public func hsvColor(_ components: [CGFloat]) -> Color {
        Self.hsvColor(components, space: profile.mode.colorSpace, headroom: headroom)
    }

    /// Convenience function to get color space appropriate colors from RGBA components.
    public func rgbColors(_ colors: [[CGFloat]]) -> [Color] {
        let space = profile.mode.colorSpace
        return colors.map { Self.rgbColor($0, space: space, headroom: headroom) }
    }

    /// Convenience function to get color space appropriate colors from HSVA components.
    public func hsvColors(_ colors: [[CGFloat]]) -> [Color] {
        let space = profile.mode.colorSpace
        return colors.map { Self.hsvColor($0, space: space, headroom: headroom) }
    }

    /// Create a color from RGBA components that is calibrated for the color space and headroom.
    public static func rgbColor(_ components: [CGFloat],
                                space: CGColorSpace,
                                headroom: Headroom) -> Color {
        guard let cgColor = CGColor(colorSpace: space, components: components) else {
            return Color(.displayP3, red: components[0], green: components[1],
                         blue: components[2], opacity: components[3])
        }
        return Color(cgColor: cgColor)
            .headroom(headroom.potential)
    }

    /// Create a color from HSVA components that is calibrated for the color space and headroom.
    public static func hsvColor(_ components: [CGFloat],
                                space: CGColorSpace,
                                headroom: Headroom) -> Color {
        let (hue, sat, val, opa) = (components[0], components[1], components[2], components[3])
        let p3Color = NativeColor(hue: hue, saturation: sat, brightness: val, alpha: opa)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        p3Color.getRed(&r, green: &g, blue: &b, alpha: &a)
        guard let cgColor = CGColor(colorSpace: space, components: [r, g, b, a]) else {
            return Color(.displayP3, red: components[0], green: components[1],
                         blue: components[2], opacity: components[3])
        }
        return Color(cgColor: cgColor)
            .headroom(headroom.potential)
    }
}
