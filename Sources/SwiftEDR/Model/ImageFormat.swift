//
//  ImageFormat.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/19/26.
//

import Foundation
import ImageIO

/// Used with image and data utilities for examining HDR image attributes.
public struct ImageInfo: BaseModel {
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

    public let format: Format
    public let headroom: CGFloat
}
