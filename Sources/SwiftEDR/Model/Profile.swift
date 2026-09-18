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

    /// Constrains the maximum requested headroom. This is reflected in both current and potential headroom reported to the app.
    public var maxHeadroom: CGFloat

    /// Flags that control special rendering behaviors.
    public var options: Options

    /// Initialize an EDR Profile.
    /// - Parameters:
    ///   - mode: Determines color space, bit depth, and dynamic range behaviors.
    ///   - bloom: Controls bloom effect.
    ///   - maximumHeadroom: Limits the maximum current and potential headroom reported to the application.
    ///   - options: Controls special rendering options.
    public init(mode: Mode, bloom: Bloom, maxHeadroom: CGFloat = 1024, options: Options = []) {
        self.mode = mode
        self.bloom = bloom
        self.maxHeadroom = maxHeadroom
        self.options = options
    }
}

// MARK: Setup Convenience

extension Profile {
    /// A colorspace appropriate for the current mode and options.
    public var colorSpace: CGColorSpace {
        switch mode {
        case  .hdr, .edr:
            return CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3)!
        case .sdr:
            return options.isLinearColorSpace ? CGColorSpace(name: CGColorSpace.linearDisplayP3)! : CGColorSpace(name: CGColorSpace.displayP3)!
        }
    }

    /// A rendering mode appropriate for the curent mode and options.
    public var renderMode: ColorRenderingMode {
        switch mode {
        case .hdr, .edr:
            return .extendedLinear
        case .sdr:
            return options.isLinearColorSpace ? .linear : .nonLinear
        }
    }

    /// A mode-appropriate value for use with with `.allowedDynamicRange` SwiftUI modifier.
    public var relativeDynamicRange: Image.DynamicRange {
        switch mode {
        case .hdr:
            return options.contains(.constrainedHDR) ? .constrainedHigh : .high
        case .edr, .sdr:
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
        /// Extended color range and bit depth for precise color math, displayed in the standard SRGB color range.
        case edr
        /// Extended color range and bit depth for precise color math displayed in an extended HDR color range with higher contrast and absolute brightness.
        case hdr
    }

    /// Attributes related to the Bloom effect.
    public struct Bloom: BaseModel {
        public enum Mode: BaseModel {
            case luminance
            case color
        }
        /// The bloom threshold mode.
        public var mode: Mode
        /// Radius of the bloom as a fraction of view "radius" (the lesser of either dimension), in the range [0, 1].
        public var radius: CGFloat
        /// Color value threshold at which the bloom triggers.
        public var threshold: CGFloat
        /// Width of the soft knee applied around the threshold point.
        public var kneeWidth: CGFloat
        /// Opacity of the bloom effect, in the range [0, 1].
        public var intensity: CGFloat
        /// A value which controls to what degree bloom threshold varies with changing headroom, in the range [0, 1].
        public var adaptivity: CGFloat

        public init(mode: Mode = .luminance, radius: CGFloat = 0, threshold: CGFloat = 1,
                    kneeWidth: CGFloat = 0, intensity: CGFloat = 0, adaptivity: CGFloat = 0.1) {
            self.mode = mode
            self.radius = radius
            self.threshold = threshold
            self.kneeWidth = kneeWidth
            self.intensity = intensity
            self.adaptivity = adaptivity
        }

        public static let hdr = Bloom(radius: 0.035, threshold: 1.0, kneeWidth: 0.2, intensity: 1.0)
        public static let edr = Bloom(radius: 0.035, threshold: 1.0, kneeWidth: 0.1, intensity: 1.0)
        public static let sdr = Bloom(radius: 0.035, threshold: 1.0, kneeWidth: 0.1, intensity: 1.0)
        public static let none = Bloom(radius: 0.0, threshold: 1.0, kneeWidth: 0.0, intensity: 0.0)
    }

    /// Future thing.
    public struct ColorInfo {
        let colorSpace: CGColorSpace
        let bitmapInfo: UInt32
        let bitsPerComponent: Int
        // TODO: Additional support for export encoding...
    }

    /// Special options that can be used to affect rendering.
    public struct Options: OptionSet, BaseModel {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        /// When enabled, uses a linear colorspace, rather than the default P3 colorspace.
        public static let linearColorSpace = Self(rawValue: 1 << 0)
        /// When enabled with HDR mode, tones down the HDR brightness relative to nearby SDR content.
        public static let constrainedHDR = Self(rawValue: 1 << 1)
        /// When enabled, only bloom highlights are drawn.
        public static let bloomHighlightsOnly = Self(rawValue: 1 << 2)
        /// If set, enables default tone mapping. Experimental, not all that useful at the moment.
        public static let toneMapDefault = Self(rawValue: 1 << 3)

        public var isLinearColorSpace: Bool {
            get { contains(.linearColorSpace) }
            set { if newValue { insert(.linearColorSpace) } else { remove(.linearColorSpace) } }
        }

        public var isConstrainedHDR: Bool {
            get { contains(.constrainedHDR) }
            set { if newValue { insert(.constrainedHDR) } else { remove(.constrainedHDR) } }
        }

        public var isBloomHighlightsOnly: Bool {
            get { contains(.bloomHighlightsOnly) }
            set { if newValue { insert(.bloomHighlightsOnly) } else { remove(.bloomHighlightsOnly) } }
        }

        public var isToneMapDefault: Bool {
            get { contains(.toneMapDefault) }
            set { if newValue { insert(.toneMapDefault) } else { remove(.toneMapDefault) } }
        }
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
