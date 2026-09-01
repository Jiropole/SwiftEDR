//
//  EDRModifier.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 8/31/26.
//

import SwiftUI

/// Applies EDR (extended dynamic range) color precision and display to the view content.

public struct EDRModifier: ViewModifier {
    /// EDR picture configuration.
    public let picture: Picture

    /// Diagnostic options.
    public var options: Diagnostics = []

    public init(picture: Picture, options: Diagnostics) {
        self.picture = picture
        self.options = options
    }

    public func body(content: Content) -> some View {
        Group {
            switch picture.mode {
            case .hdr:
                // Expand the allowed dynamic range for HDR.
                toneMapped(content: content)
                    .allowedDynamicRange(picture.relativeDynamicRange)
            default:
                // Other modes can still be tone mapped.
                toneMapped(content: content)
            }
        }
    }

    public func toneMapped(content: Content) -> some View {
        content
            .modifier(BloomModifier(picture: picture, options: options))
            .layerEffect(
                // Apply tone mapping
                ShaderLibrary.bundle(Bundle.module).cinematicToneMap(),
                maxSampleOffset: .zero
            )
    }
}
