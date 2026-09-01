//
//  Picture.swift
//  EDRCanvas
//
//  Created by Jesse Hemingway on 8/28/26.
//

import Foundation
import SwiftUI

#if os(iOS) || os(visionOS)
public typealias NativeColor = UIColor
#elseif os(macOS)
import AppKit
public typealias NativeColor = NSColor
#endif

/// Defines a profile of a color model and customize
public struct Profile: BaseModel {
    /// Selects EDR mode.
    public var mode: Mode

    /// Controls optional bloom effect.
    public var bloom: Bloom

    /// When enabled with HDR mode, tones down the HDR brightness relative to nearby SDR content.
    public var constrainedHDR: Bool

    public init(mode: Mode, bloom: Bloom, constrainedHDR: Bool = true) {
        self.mode = mode
        self.bloom = bloom
        self.constrainedHDR = constrainedHDR
    }
}

// MARK: Color Convenience

extension Profile {
    /// Convenience function to get a color space appropriate color.
    public func rgbColor(_ components: [CGFloat]) -> Color {
        Self.rgbColor(components, space: mode.colorSpace)
    }

    /// Convenience function to get color space appropriate colors.
    public func rgbColors(_ colors: [[CGFloat]]) -> [Color] {
        let space = mode.colorSpace
        return colors.map { Self.rgbColor($0, space: space) }
    }

    /// Convenience function to get a color space appropriate color.
    public func hsvColor(_ components: [CGFloat]) -> Color {
        Self.hsvColor(components, space: mode.colorSpace)
    }

    /// Convenience function to get color space appropriate colors.
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
        let p3UIColor = NativeColor(hue: hue, saturation: sat, brightness: val, alpha: opa)
        let cgColor = p3UIColor.cgColor
        guard let convertedColor = cgColor
            .converted(to: space, intent: .perceptual, options: nil) else {
            return Color(cgColor: cgColor)
        }
        return Color(cgColor: convertedColor)
    }

    /// A mode-appropriate value for use with with `.allowedDynamicRange` SwiftUI modifier.
    public var relativeDynamicRange: Image.DynamicRange {
        mode == .hdr ? (constrainedHDR ? .constrainedHigh : .high) : .standard
    }
}

// MARK: Submodels

extension Profile {
    /// A set of EDR options selecting between different drawing bit depth, color range and tone mapping.
    public enum Mode: BaseModel {
        /// Standard color range and bit depth.
        case sdr
        /// Extended color range and bit depth for precise color math, displayed in the standard SRGB color range.
        case edr
        /// Extended color range and bit depth for precise color math displayed in an extended HDR color range with higher contrast and absolute brightness.
        case hdr

        public var colorSpace: CGColorSpace {
            switch self {
            case .sdr:
                return CGColorSpaceCreateDeviceRGB()
            case .edr:
                return CGColorSpace(name: CGColorSpace.displayP3)!
            case .hdr:
                return CGColorSpace(name: CGColorSpace.itur_2100_HLG)!
            }
        }

        public var renderMode: ColorRenderingMode {
            switch self {
            case .sdr:
                return .nonLinear
            default:
                return .extendedLinear
            }
        }

        public var colorInfo: ColorInfo {
            switch self {
            case .sdr:
                return ColorInfo(colorSpace: colorSpace,
                                 bitmapInfo: (CGImageAlphaInfo.premultipliedFirst.rawValue |
                                              CGImageByteOrderInfo.order32Big.rawValue),
                                 bitsPerComponent: 8)
            default:
                return ColorInfo(colorSpace: colorSpace,
                                 bitmapInfo: (CGImageAlphaInfo.premultipliedLast.rawValue |
                                              CGImageByteOrderInfo.order16Little.rawValue |
                                              CGBitmapInfo.floatComponents.rawValue),
                                 bitsPerComponent: 16)
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

        public static let hdr = Bloom(radius: 0.05, threshold: 1.0, kneeWidth: 0.2, intensity: 1.0)
        public static let edr = Bloom(radius: 0.05, threshold: 0.9, kneeWidth: 0.1, intensity: 1.0)
        public static let sdr = Bloom(radius: 0.05, threshold: 0.9, kneeWidth: 0.1, intensity: 1.0)
        public static let none = Bloom(radius: 0.0, threshold: 1.0, kneeWidth: 0.0, intensity: 1.0)
    }

    public struct ColorInfo {
        let colorSpace: CGColorSpace
        let bitmapInfo: UInt32
        let bitsPerComponent: Int
        // TODO: Additional support for export encoding...
    }

    public struct Defaults {
        public static let sdr = Profile(mode: .sdr, bloom: .none)
        public static let edr = Profile(mode: .edr, bloom: .none)
        public static let hdr = Profile(mode: .hdr, bloom: .none)
        public static let sdrBloom = Profile(mode: .sdr, bloom: .sdr)
        public static let edrBloom = Profile(mode: .edr, bloom: .edr)
        public static let hdrBloom = Profile(mode: .hdr, bloom: .hdr)
    }
}

