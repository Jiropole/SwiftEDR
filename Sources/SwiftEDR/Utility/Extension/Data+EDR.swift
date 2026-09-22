//
//  Data+EDR.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/19/26.
//

import Foundation
import ImageIO

public extension Data {
    /// Inspects the image metadata bytes to determine the HDR rendering format and ideal headroom.
    var edrImageInfo: ImageInfo {
        guard let source = CGImageSourceCreateWithData(self as CFData, nil) else {
            return .init(format: .sdr, headroom: 1.0)
        }
        return source.edrImageInfo
    }
}
