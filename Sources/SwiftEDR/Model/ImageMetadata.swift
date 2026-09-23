//
//  ImageMetadata.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/19/26.
//

import Foundation
import ImageIO

/// Used with image and data utilities for examining HDR image attributes.
public struct ImageMetadata: BaseModel {
    public enum Format: String, BaseModel {
        /// Standard Dynamic Range image.
        case sdr
        /// True HDR encoding lacking an embedded SDR fallback (e.g. Rec.2100 HLG/PQ).
        case isoHDR
        /// Proprietary Apple HDR Gain Map layered over an SDR base image.
        case appleGainMap
        /// Industry-standard ISO 21496-1 Gain Map layered over an SDR base image.
        case isoGainMap

        /// Convenience flag.
        public var isHDR: Bool {
            self != .sdr
        }

        /// Default EDR mode for this format.
        public var defaultMode: Profile.Mode {
            self == .sdr ? .sdr : .hdr
        }
    }

    /// EDR format of the image.
    public let format: Format
    /// EDR headroom used by the image.
    public let headroom: CGFloat

    public static let `default` = Self(format: .sdr, headroom: 1.0)
}
