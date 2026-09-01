//
//  EDRCanvas.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 8/31/26.
//

import SwiftUI

/// Use SwiftEDRCanvas as direct replacement for Swift Canvas, extended with support EDR color handling. \

public struct EDRCanvas<Payload: Any>: View {
    public typealias DrawFunction = (_ context: GraphicsContext,
                                     _ size: CGSize,
                                     _ payload: Payload) -> Void

    private let profile: Profile
    private let isOpaque: Bool
    private let rendersAsynchronously: Bool
    private let options: Diagnostics
    private let payload: Payload
    private let onDraw: DrawFunction

    public init(profile: Profile,
                isOpaque: Bool = false,
                rendersAsynchronously: Bool = false,
                options: Diagnostics = [],
                payload: Payload,
                onDraw: @escaping DrawFunction) {
        self.profile = profile
        self.isOpaque = isOpaque
        self.rendersAsynchronously = rendersAsynchronously
        self.options = options
        self.payload = payload
        self.onDraw = onDraw
    }

    public var body: some View {
        Canvas(opaque: isOpaque, colorMode: canvasColorMode, rendersAsynchronously: rendersAsynchronously) { context, size in
            onDraw(context, size, payload)
        }
        .modifier(EDRModifier(profile: profile, options: options))
    }
}

private extension EDRCanvas {
    var canvasColorMode: ColorRenderingMode {
        switch profile.mode {
        case .sdr:
            return .nonLinear
        default:
            return .extendedLinear
        }
    }
}
