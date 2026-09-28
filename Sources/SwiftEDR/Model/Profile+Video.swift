//
//  Profile+Video.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/27/26.
//

import AVFoundation
import VideoToolbox

extension Profile {
    /// Selects the codec used for video encoding.
    public enum VideoCodec: BaseModel {
        /// Most universally supported, but does not support HDR streams.
        case h264
        /// Most efficient, and required for HDR streams, but enjoys less universal support.
        case hevc
    }

    /// Selects the family of HDR color transfer functions used for video encoding.
    public enum VideoHDRTransfer: BaseModel {
        /// Hybrid Log Gamma transfer; most universally supported and gracefully downgrades to SDR.
        case hlg
        /// Perceptual Quantization; has fixed brightness rules, narrower support, and downgrades to SDR via display system tone mapping.
        case pq

        var colorSpace: CGColorSpace {
            switch self {
            case .hlg:
                return CGColorSpace(name: CGColorSpace.itur_2100_HLG)!
            case .pq:
                return CGColorSpace(name: CGColorSpace.itur_2100_PQ)!
            }
        }
    }

    /// Wraps various video writer and pixel buffer setup attributes.
    public struct VideoSetupInfo {
        public var bitmapInfo: UInt32
        public var pixelFormat: UInt32
        public var bitsPerComponent: Int
        public var adapterProperties: [String: Any]
        public var colorSpace: CGColorSpace
    }

    public enum VideoProfile {
        /// Specifies an SDR video stream from an 8-bit standard input buffer using `codec`.
        case sdr8Bit(codec: VideoCodec = .h264)
        /// Specifies an SDR video stream from a 16-bit extended input buffer using `codec`.
        case sdr16Bit(codec: VideoCodec = .hevc)
        /// Specifies an HDR video stream from a 16-bit extended input buffer using `codec`.
        case hdr(transfer: VideoHDRTransfer = .hlg)

        // MARK: - Codec & Compression Configuration

        public var codec: AVVideoCodecType {
            switch self {
            case .sdr8Bit(let codec), .sdr16Bit(let codec):
                return codec == .h264 ? .h264 : .hevc // SDR can use either codec
            case .hdr:
                return .hevc // HDR requires 10-bit HEVC
            }
        }

        public var profileLevel: String {
            switch self {
            case .sdr8Bit(let codec):
                return (codec == .h264
                        ? kVTProfileLevel_H264_High_AutoLevel
                        : kVTProfileLevel_HEVC_Main_AutoLevel) as String
            case .sdr16Bit(let codec):
                // If exporting a premium 16-bit linear buffer to SDR via HEVC,
                // leverage Main10 to keep 10-bit precision and avoid 8-bit truncation banding.
                return (codec == .h264
                        ? kVTProfileLevel_H264_High_AutoLevel
                        : kVTProfileLevel_HEVC_Main10_AutoLevel) as String
            case .hdr:
                return kVTProfileLevel_HEVC_Main10_AutoLevel as String
            }
        }

        // MARK: - Color Properties (Nesting at Root Level)

        /// AVFoundation color properties typically used with the `AVVideoColorPropertiesKey`.
        public var colorProperties: [String: Any] {
            switch self {
            case .sdr8Bit, .sdr16Bit:
                return [
                    AVVideoColorPrimariesKey: AVVideoColorPrimaries_P3_D65,
                    AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
                    AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2
                ]
            case .hdr(let transfer):
                switch transfer {
                case .hlg:
                    return [
                        AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_2020,
                        AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_2100_HLG,
                        AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_2020
                    ]
                case .pq:
                    return [
                        AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_2020,
                        AVVideoTransferFunctionKey: AVVideoTransferFunction_SMPTE_ST_2084_PQ,
                        AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_2020
                    ]
                }
            }
        }

        /// Extra compression properties, e.g. for PQ transfer.
        public var extraCompressionProperties: [String: Any] {
            guard case .hdr(let transfer) = self, transfer == .pq else { return [:] }
            return [
                // Standard 1,000-nit HDR10 mastering metadata
                // using literal string keys for SMPTE ST 2086 mastering display metrics.
                kCVImageBufferMasteringDisplayColorVolumeKey as String: [
                    "RedPrimaries": [0.680, 0.320],
                    "GreenPrimaries": [0.265, 0.690],
                    "BluePrimaries": [0.150, 0.060],
                    "WhitePoint": [0.3127, 0.3290],
                    "MaxLuminance": 1000.0,
                    "MinLuminance": 0.005
                ],
                kCVImageBufferContentLightLevelInfoKey as String: [
                    "MaxCLL": 1000,   // Max Content Light Level
                    "MaxFALL": 400    // Max Frame Average Light Level
                ]
            ]
        }

            // MARK: - Video Writer and Pixel Buffer Setup

        /// Convenience accessor to wrap typical output properties for use with e.g. with `AVAssetWriterInputPixelBufferAdaptor`.
        public func adapterProperties(withBitrate bitrate: Int) -> [String: Any] {
            [
                AVVideoCodecKey: codec,
                AVVideoColorPropertiesKey: colorProperties,
                AVVideoCompressionPropertiesKey: [
                    AVVideoProfileLevelKey: profileLevel,
                    AVVideoAverageBitRateKey: NSNumber(value: bitrate)
                ]
                    .merging(extraCompressionProperties) { _, new in new }
            ]
        }

        /// Convenience accessor to wrap typical output properties and buffer configuration values.
        public func setupInfo(withBitrate bitrate: Int) -> VideoSetupInfo {
            var hdrBitmapInfo: UInt32 {
                (CGImageAlphaInfo.premultipliedLast.rawValue |
                 CGImageByteOrderInfo.order16Little.rawValue |
                 CGBitmapInfo.floatComponents.rawValue)
            }

            switch self {
            case .sdr8Bit:
                return .init(bitmapInfo: (CGImageAlphaInfo.premultipliedFirst.rawValue |
                                          CGImageByteOrderInfo.order32Big.rawValue),
                             pixelFormat: kCVPixelFormatType_32ARGB,
                             bitsPerComponent: 8,
                             adapterProperties: adapterProperties(withBitrate: bitrate),
                             colorSpace: CGColorSpace(name: CGColorSpace.displayP3)!)
            case .sdr16Bit:
                return .init(bitmapInfo: hdrBitmapInfo,
                             pixelFormat: kCVPixelFormatType_64RGBAHalf,
                             bitsPerComponent: 16,
                             adapterProperties: adapterProperties(withBitrate: bitrate),
                             colorSpace: CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3)!)

            case .hdr(let transfer):
                return .init(bitmapInfo: hdrBitmapInfo,
                             pixelFormat: kCVPixelFormatType_64RGBAHalf,
                             bitsPerComponent: 16,
                             adapterProperties: adapterProperties(withBitrate: bitrate),
                             colorSpace: transfer.colorSpace)
            }
        }

        /// Calculates a recommended bitrate, where `quality` is in the range [0, 1].
        /// - Parameters:
        ///   - quality: Determines quality level in the [0, 1].
        ///   There is a logarithmic relationship between this value and the resulting visual quality,
        ///   i.e. the difference between 0.4 and 0.6 is larger than 0.6 to 0.8.
        ///   - dimensions: The width and height of the output video.
        ///   - framerate: Target framerate of the output video.
        ///   - brppRange: Determines a base bitrate-per-pixel range, where 0.05 is highly compressed, 0.4 is near-lossless.
        /// - Returns: Ideal bitrate for the given parameters.
        public func bitrateForQuality(_ quality: CGFloat,
                                      dimensions: CGSize,
                                      framerate: CGFloat,
                                      brppRange: ClosedRange<CGFloat> = 0.05...0.4) -> Int {
            // Establish a baseBpp for H.264 compression and use a 1080p base target for spatial scaling.
            let baseBpp = brppRange.lowerBound + (brppRange.upperBound - brppRange.lowerBound) * quality
            let resolutionFactor = dimensions.height / 1080.0

            // Apply logarithmic efficiency scaling to scale gracefully from 540p up to 8K.
            // 540p scales BPP up slightly (~1.1x), 1080p stays at 1.0, 4K scales down (~0.82x), 8K down (~0.73x).
            let spatialEfficiency = pow(resolutionFactor, -0.15)
            var targetBpp = baseBpp * spatialEfficiency

            // For HEVC output, apply HEVC's 40-50% bitrate efficiency reduction over H.264.
            if self.codec == .hevc {
                targetBpp *= 0.55
            }

            // 10-bit and 16-bit HLG/PQ require extra data overhead to prevent banding in color gradients.
            switch self {
            case .sdr16Bit, .hdr:
                targetBpp *= 1.35 // Give 35% headroom back to preserve high dynamic range detail
            default:
                break
            }

            // Apply a non-linear framerate scalar, based on higher framerates have diminishing inter-frame delta,
            // and lower framerates needing more bits to keep them sharp.
            let framerateScalar = 2 - pow(framerate / 30, 1/3)

            // Calculate resulting bits per second
            let totalPixelsPerSecond = dimensions.width * dimensions.height * framerate
            let calculatedBitrate = totalPixelsPerSecond * targetBpp * framerateScalar

//            print("q: \(quality), bbpp: \(baseBpp), eff: \(spatialEfficiency), tbpp: \(targetBpp), frs: \(framerateScalar)")
//            print("bitrate: \(calculatedBitrate)")

            return Int(calculatedBitrate)
        }

        // MARK: - Dynamic Pixel Buffer Tagging

        /// Tag a pixel buffer with given color transfer.
        /// - Parameters:
        ///   - pixelBuffer: Pixel buffer to be tagged.
        ///   - nonlinear: Determines the transfer function between input and output buffers. Default: linear.
        public func tag(pixelBuffer: CVPixelBuffer, linearColor: Bool) {
            let transferFunction = (linearColor
                                    ? kCVImageBufferTransferFunction_Linear
                                    : kCVImageBufferTransferFunction_ITU_R_709_2)
            switch self {
            case .sdr8Bit, .sdr16Bit:
                CVBufferSetAttachment(pixelBuffer, kCVImageBufferColorPrimariesKey,
                                      kCVImageBufferColorPrimaries_P3_D65 as CFString, .shouldPropagate)
                CVBufferSetAttachment(pixelBuffer, kCVImageBufferYCbCrMatrixKey,
                                      kCVImageBufferYCbCrMatrix_ITU_R_709_2 as CFString, .shouldPropagate)

            default: break
            }
            // Always set transfer function
            CVBufferSetAttachment(pixelBuffer, kCVImageBufferTransferFunctionKey,
                                  transferFunction as CFString, .shouldPropagate)
        }
    }
}
