//
//  Data+EDR.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/19/26.
//

import Foundation
import ImageIO

public extension Data {
    /// Inspects the image metadata bytes to determine the HDR rendering format.
    var edrImageFormat: ImageFormat {
        guard let source = CGImageSourceCreateWithData(self as CFData, nil) else {
            return .sdr
        }
        return source.edrImageFormat
    }
}
