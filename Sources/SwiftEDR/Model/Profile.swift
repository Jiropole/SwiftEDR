//
//  Picture.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 8/28/26.
//

import Foundation
import SwiftUI

/// Defines a profile of a color model and customize
public struct Profile: BaseModel {
    /// Selects EDR mode.
    public var mode: Mode

    /// Controls optional bloom effect.
    public var bloom: Bloom

    /// Flags that control special or debugging behaviors.
    public var options: Options

    public init(mode: Mode, bloom: Bloom, options: Options = []) {
        self.mode = mode
        self.bloom = bloom
        self.options = options
    }
}

// MARK: Color Convenience

extension Profile {
    /// Convenience function to get a color space appropriate color from RGBA components.
    public func rgbColor(_ components: [CGFloat]) -> Color {
        Self.rgbColor(components, space: mode.colorSpace)
    }

    /// Convenience function to get color space appropriate colors from RGBA components.
    public func rgbColors(_ colors: [[CGFloat]]) -> [Color] {
        let space = mode.colorSpace
        return colors.map { Self.rgbColor($0, space: space) }
    }

    /// Convenience function to get a color space appropriate color from HSVA components.
    public func hsvColor(_ components: [CGFloat]) -> Color {
        Self.hsvColor(components, space: mode.colorSpace)
    }

    /// Convenience function to get color space appropriate colors from HSVA components.
    public func hsvColors(_ colors: [[CGFloat]]) -> [Color] {
        let space = mode.colorSpace
        return colors.map { Self.hsvColor($0, space: space) }
    }

    /// Create a color from RGBA components that is calibrated for the color space.
    public static func rgbColor(_ components: [CGFloat],
                                space: CGColorSpace) -> Color {
        guard let cgColor = CGColor(colorSpace: space, components: components) else {
            return Color(.displayP3, red: components[0], green: components[1],
                         blue: components[2], opacity: components[3])
        }
        return Color(cgColor: cgColor)
    }

    /// Create a color from HSVA components that is calibrated for the color space.
    public static func hsvColor(_ components: [CGFloat],
                                space: CGColorSpace) -> Color {
        let (hue, sat, val, opa) = (components[0], components[1], components[2], components[3])
        let p3Color = NativeColor(hue: hue, saturation: sat, brightness: val, alpha: opa)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        p3Color.getRed(&r, green: &g, blue: &b, alpha: &a)
        guard let cgColor = CGColor(colorSpace: space, components: [r, g, b, a]) else {
            return Color(.displayP3, red: components[0], green: components[1],
                         blue: components[2], opacity: components[3])
        }
        return Color(cgColor: cgColor)
    }

    /// A mode-appropriate value for use with with `.allowedDynamicRange` SwiftUI modifier.
    public var relativeDynamicRange: Image.DynamicRange {
        switch mode {
        case .hdr:
            return options.contains(.constrainedHDR) ? .constrainedHigh : .high
        case .edr, .sdr, .sdrNonlinear:
            return .standard
        }
    }

    /// A convenience function to get a modified (often simplified) version of the profile.
    public func withBloom(_ bloom: Bloom, options: Options? = []) -> Profile {
        Profile(mode: self.mode, bloom: bloom, options: options ?? self.options)
    }
}

// MARK: Submodels

extension Profile {
    /// A set of EDR options selecting between different drawing bit depth, color range and tone mapping.
    public enum Mode: BaseModel {
        /// Standard color range and bit depth with linear color.
        case sdr
        /// Standard color range and bit depth with nonlinear color (displayP3).
        case sdrNonlinear
        /// Extended color range and bit depth for precise color math, displayed in the standard SRGB color range.
        case edr
        /// Extended color range and bit depth for precise color math displayed in an extended HDR color range with higher contrast and absolute brightness.
        case hdr

        public var colorSpace: CGColorSpace {
            switch self {
            case  .hdr, .edr:
                return CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3)!
            case .sdr:
                return CGColorSpace(name: CGColorSpace.linearDisplayP3)!
            case .sdrNonlinear:
                return CGColorSpace(name: CGColorSpace.displayP3)!
            }
        }

        public var renderMode: ColorRenderingMode {
            switch self {
            case .hdr, .edr:
                return .extendedLinear
            case .sdr:
                return .linear
            case .sdrNonlinear:
                return .nonLinear
            }
        }

        public var colorInfo: ColorInfo {
            switch self {
            case .hdr, .edr:
                return ColorInfo(colorSpace: colorSpace,
                                 bitmapInfo: (CGImageAlphaInfo.premultipliedLast.rawValue |
                                              CGImageByteOrderInfo.order16Host.rawValue |
                                              CGBitmapInfo.floatComponents.rawValue),
                                 bitsPerComponent: 16)
            case .sdr, .sdrNonlinear:
                return ColorInfo(colorSpace: colorSpace,
                                 bitmapInfo: (CGImageAlphaInfo.premultipliedFirst.rawValue |
                                              CGImageByteOrderInfo.order32Big.rawValue),
                                 bitsPerComponent: 8)
            }
        }
    }

    public struct Bloom: BaseModel {
        /// Radius of the bloom as a fraction of view "radius" (the lesser of either dimension).
        public var radius: CGFloat = 0
        /// Color value threshold at which the bloom triggers.
        public var threshold: CGFloat = 1
        /// Width of the soft knee applied around the threshold point.
        public var kneeWidth: CGFloat = 0
        /// Opacity of the bloom effect.
        public var intensity: CGFloat = 0

        public init(radius: CGFloat, threshold: CGFloat, kneeWidth: CGFloat, intensity: CGFloat) {
            self.radius = radius
            self.threshold = threshold
            self.kneeWidth = kneeWidth
            self.intensity = intensity
        }

        public static let hdr = Bloom(radius: 0.035, threshold: 1.0, kneeWidth: 0.2, intensity: 1.0)
        public static let edr = Bloom(radius: 0.035, threshold: 1.0, kneeWidth: 0.1, intensity: 1.0)
        public static let sdr = Bloom(radius: 0.035, threshold: 1.0, kneeWidth: 0.1, intensity: 1.0)
        public static let none = Bloom(radius: 0.0, threshold: 1.0, kneeWidth: 0.0, intensity: 0.0)
    }

    public struct ColorInfo {
        let colorSpace: CGColorSpace
        let bitmapInfo: UInt32
        let bitsPerComponent: Int
        // TODO: Additional support for export encoding...
    }

    public struct Options: OptionSet, BaseModel {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        /// When enabled, only bloom highlights are drawn.
        public static let bloomHighlightsOnly = Self(rawValue: 1 << 0)
        /// When enabled with HDR mode, tones down the HDR brightness relative to nearby SDR content.
        public static let constrainedHDR = Self(rawValue: 1 << 1)
        /// If set, enables default tone mapping. Experimental.
        public static let toneMapDefault = Self(rawValue: 1 << 2)

        public var isBloomHighlightsOnly: Bool {
            get { contains(.bloomHighlightsOnly) }
            set { if newValue { insert(.bloomHighlightsOnly) } else { remove(.bloomHighlightsOnly) } }
        }

        public var isConstrainedHDR: Bool {
            get { contains(.constrainedHDR) }
            set { if newValue { insert(.constrainedHDR) } else { remove(.constrainedHDR) } }
        }

        public var isToneMapDefault: Bool {
            get { contains(.toneMapDefault) }
            set { if newValue { insert(.toneMapDefault) } else { remove(.toneMapDefault) } }
        }
    }

    public struct Defaults {
        public static let sdrNonlinear = Profile(mode: .sdrNonlinear, bloom: .none)
        public static let sdr = Profile(mode: .sdr, bloom: .none)
        public static let edr = Profile(mode: .edr, bloom: .none)
        public static let hdr = Profile(mode: .hdr, bloom: .none)

        public static let sdrBloomNonlinear = Profile(mode: .sdrNonlinear, bloom: .sdr)
        public static let sdrBloom = Profile(mode: .sdr, bloom: .sdr)
        public static let edrBloom = Profile(mode: .edr, bloom: .edr)
        public static let hdrBloom = Profile(mode: .hdr, bloom: .hdr)
    }
}
