//
//  CGImageSource+EDR.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/19/26.
//

import SwiftUI
import ImageIO

public extension CGImageSource {
    /// Inspects the image source metadata to determine its exact HDR rendering format.
    var edrImageFormat: ImageFormat {
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
}
