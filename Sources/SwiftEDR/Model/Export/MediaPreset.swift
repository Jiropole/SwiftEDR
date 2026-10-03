//
//  MediaPreset.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/28/26.
//

import AVFoundation
import VideoToolbox

public protocol MediaPreset {
    /// File universal type.
    var utType: UTType { get }

    /// Standard file extension.
    var fileExtension: String { get }
}
