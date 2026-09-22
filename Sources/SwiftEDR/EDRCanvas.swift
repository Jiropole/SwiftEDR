//
//  EDRCanvas.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 8/31/26.
//

import SwiftUI

/// Use SwiftEDRCanvas as direct replacement for Swift Canvas, extended with support EDR color handling.
public struct EDRCanvas: View {
    
    /// Callback function used by the package client to render the canvas.
    public typealias DrawFunction = (_ context: inout GraphicsContext,
                                     _ size: CGSize,
                                     _ palette: Palette) -> Void

    /// Same as Canvas parameter `opaque`.
    private let isOpaque: Bool

    /// Same as Canvas parameter `rendersAsynchronously`.
    private let rendersAsynchronously: Bool

    /// Draw function called when the canvas needs to be rendered.
    private let onDraw: DrawFunction

    @Environment(\.edrPalette) private var palette

    /// Initialize an EDR Canvas with a given draw function.
    /// - Parameters:
    ///   - opaque: Same as Canvas parameter `opaque`.
    ///   - rendersAsynchronously: Same as Canvas parameter `rendersAsynchronously`.
    ///   - onDraw: Draw function called when the canvas needs to be rendered.
    public init(opaque: Bool = false,
                rendersAsynchronously: Bool = false,
                onDraw: @escaping DrawFunction) {
        self.isOpaque = opaque
        self.rendersAsynchronously = rendersAsynchronously
        self.onDraw = onDraw
    }

    public var body: some View {
        Canvas(opaque: isOpaque,
               colorMode: palette.profile.renderMode,
               rendersAsynchronously: rendersAsynchronously) { context, size in

            // Read intantaneous headroom for use with HDR mode.
            let headroom = Headroom.readHeadroom()?.headroomForProfile(palette.profile) ?? .init()

            // Draw using the current profile, or else default to SDR.
            onDraw(&context,
                   size,
                   .init(profile: palette.profile, headroom: headroom))
        }
    }
}
