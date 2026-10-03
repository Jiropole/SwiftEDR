//
//  ImagePreset.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/28/26.
//

import AVFoundation
import VideoToolbox

public enum ImagePreset: MediaPreset {
    public typealias HDRTransfer = VideoPreset.HDRTransfer

    /// Specifies an SDR image from an 8-bit standard input buffer to be encoded as a PNG file.
    case png

    /// Specifies an SDR image from an 8-bit standard input buffer to be encoded as a JPEG file.
    case jpg(quality: CGFloat)

    /// Specifies an SDR image from a 16-bit extended input buffer to be encoded as an HEIC file.
    case sdrHeic(quality: CGFloat)

    /// Specifies an HDR image from a 16-bit extended input buffer to be encoded as an HEIC file.
    case hdrHeic(quality: CGFloat, transfer: HDRTransfer)

    /// AVFoundation image properties useful with the likes of `CGImageDestinationAddImage`.
    public var imageAdapterProperties: [CFString: Any] {
        switch self {
        case .png:
            return [:]
        case .jpg(let quality):
            return [kCGImageDestinationLossyCompressionQuality: quality]
        case .sdrHeic(let quality):
            return [kCGImageDestinationLossyCompressionQuality: quality]
        case .hdrHeic(let quality, _):
            return [kCGImageDestinationLossyCompressionQuality: quality,
                             kCGImageDestinationEncodeToISOHDR: true,
                         kCGImageDestinationEncodeToISOGainmap: true]
        }
    }

    /// Retrieve a standard color space appropriate for the preset.
    public var colorSpace: CGColorSpace {
        switch self {
        case .png, .jpg:
            return CGColorSpace(name: CGColorSpace.displayP3)!
        case .sdrHeic:
            return CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3)!
        case .hdrHeic(_, let transfer):
            return transfer.colorSpace
        }
    }

    public var utType: UTType {
        switch self {
        case .png:
            return .png
        case .jpg:
            return .jpeg
        case .sdrHeic, .hdrHeic:
            return .heic
        }
    }

    public var fileExtension: String {
        switch self {
        case .png:
            return "png"
        case .jpg:
            return "jpg"
        case .sdrHeic, .hdrHeic:
            return "heic"
        }
    }
}
