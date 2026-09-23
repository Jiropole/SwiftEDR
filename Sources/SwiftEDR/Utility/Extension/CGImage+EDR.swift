//
//  CGImage+EDR.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/23/26.
//

import CoreGraphics

extension CGImage {
    /// Collect metadata for the image, which may be limited compared to getting it from a CGImageSource.
    public var edrImageMetadata: ImageMetadata {
        ImageMetadata(format: contentHeadroom > 1 ? .isoHDR : .sdr,
                      headroom: CGFloat(contentHeadroom))
    }
}
