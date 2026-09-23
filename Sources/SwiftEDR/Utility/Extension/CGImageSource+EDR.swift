//
//  CGImageSource+EDR.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/19/26.
//

import ImageIO
import CoreGraphics
import Foundation

extension CGImageSource {
    /// Collects EDR image metadata by directly reading it from the image source.
    public var edrImageMetadata: ImageMetadata {
        let format = edrImageFormat
        return .init(format: format, headroom: edrHeadroomWithFormat(format))
    }

    /// Inspects the image source metadata to determine its SDR/HDR rendering format.
    private var edrImageFormat: ImageMetadata.Format {
        // Check for Gain Maps (Auxiliary Images)
        // Check for Standard ISO 21496-1 first, then fallback to Apple's legacy type
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, *),
           CGImageSourceCopyAuxiliaryDataInfoAtIndex(self, 0, kCGImageAuxiliaryDataTypeISOGainMap) != nil {
            return .isoGainMap
        }

        if CGImageSourceCopyAuxiliaryDataInfoAtIndex(self, 0, kCGImageAuxiliaryDataTypeHDRGainMap) != nil {
            return .appleGainMap
        }

        // 2. Check for Direct ISO HDR (Color Profile / Model Inspection)
        if let properties = CGImageSourceCopyPropertiesAtIndex(self, 0, nil) as? [CFString: Any],
           let colorSpaceName = properties[kCGImagePropertyColorModel] as? String {

            // Check if the color profile string matches an HDR standard (HLG / PQ / BT.2100)
            if colorSpaceName.contains("HLG") || colorSpaceName.contains("PQ") || colorSpaceName.contains("2100") {
                return .isoHDR
            }
        }

        return .sdr
    }

    /// Computes the content headroom multiplier without fully decoding the pixel bitmap.
    private func edrHeadroomWithFormat(_ format: ImageMetadata.Format) -> CGFloat {
        switch format {

        case .isoGainMap:
            // ISO 21496-1 uses specific metadata blocks inside the auxiliary data
            if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, *),
               let auxInfo = CGImageSourceCopyAuxiliaryDataInfoAtIndex(self, 0, kCGImageAuxiliaryDataTypeISOGainMap) as? [String: Any],
               let metadata = auxInfo[kCGImageAuxiliaryDataInfoMetadata as String] as? [String: Any] {

                // ISO standard defines maximum content boost/headroom natively
                // Check for 'max_content_boost' or the equivalent parsed key
                if let maxBoost = metadata["max_content_boost"] as? CGFloat {
                    return maxBoost // Returns direct headroom multiplier (e.g. 4.0)
                }
            }
            // Fallback to reading raw top-level properties if available
            return readTopLevelGainMapHeadroom()

        case .appleGainMap:
            // Use Method 2: Decode the MakerApple proprietary EXIF keys
            guard let properties = CGImageSourceCopyPropertiesAtIndex(self, 0, nil) as? [String: Any],
                  let makerApple = properties[kCGImagePropertyMakerAppleDictionary as String] as? [String: Any] else {
                return readTopLevelGainMapHeadroom()
            }

            if let tag33 = makerApple["33"] as? CGFloat,
               let tag48 = makerApple["48"] as? CGFloat {
                let headroom = exp2(tag33) * (1.0 + tag48)
                return max(1.0, headroom)
            }
            return readTopLevelGainMapHeadroom()

        case .isoHDR:
            // Direct HDR profiles are not relative to SDR base layers.
            // We return standard static ceiling multipliers based on the profile name.
            guard let properties = CGImageSourceCopyPropertiesAtIndex(self, 0, nil) as? [String: Any],
                  let profileName = properties[kCGImagePropertyProfileName as String] as? String else {
                return 4.0 // A safe 4.0 (2 stops) fallback default for unknown HDR
            }

            if profileName.contains("PQ") || profileName.contains("HDR10") {
                // PQ absolute peak is 10,000 nits. If mapped relative to 100 nits SDR reference, max is 100.
                // However, typical mastering targets 1,000 to 4,000 nits (Headroom 10.0 - 40.0)
                return 10.0
            } else if profileName.contains("HLG") {
                // Hybrid Log-Gamma targets roughly 1,000 nits max dynamic ceiling
                return 10.0
            }
            return 4.0

        case .sdr:
            return 1.0 // Standard dynamic range has no headroom over standard white
        }
    }

    /// Fallback helper to grab the raw top-level dynamic range boost property if the maker dictionary is stripped.
    private func readTopLevelGainMapHeadroom() -> CGFloat {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(self, 0, nil) as? [String: Any] else { return 1.0 }
        // Some processors map the parsed maximum boost natively into a top-level key
        if let rawHeadroom = properties["HDRGainMapHeadroom"] as? CGFloat {
            return max(1.0, rawHeadroom)
        }
        return 1.0
    }
}

