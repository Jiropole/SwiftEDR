//
//  Data+EDR.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/19/26.
//

import Foundation
import ImageIO

extension Data {
    /// Collects EDR image metadata by directly reading it from the image data.
    public var edrImageMetadata: ImageMetadata {
        guard let source = CGImageSourceCreateWithData(self as CFData, nil) else {
            return .init(format: .sdr, headroom: 1.0)
        }
        return source.edrImageMetadata
    }
}
