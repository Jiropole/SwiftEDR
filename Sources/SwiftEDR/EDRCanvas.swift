//
//  EDRCanvas.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 8/31/26.
//

import SwiftUI

/// Use SwiftEDRCanvas as direct replacement for Swift Canvas, extended with support EDR color handling.

public struct EDRCanvas<Payload: Any>: View {
    public typealias DrawFunction = (_ context: GraphicsContext,
                                     _ size: CGSize,
                                     _ profile: Profile,
                                     _ payload: Payload) -> Void

    private let isOpaque: Bool
    private let rendersAsynchronously: Bool
    private let payload: Payload
    private let onDraw: DrawFunction

    @Environment(\.profile) private var profile

    public init(isOpaque: Bool = false,
                rendersAsynchronously: Bool = false,
                payload: Payload,
                onDraw: @escaping DrawFunction) {
        self.isOpaque = isOpaque
        self.rendersAsynchronously = rendersAsynchronously
        self.payload = payload
        self.onDraw = onDraw
    }

    public var body: some View {
        Canvas(opaque: isOpaque,
               colorMode: profile?.mode.renderMode ?? .nonLinear,
               rendersAsynchronously: rendersAsynchronously) { context, size in
            onDraw(context,
                   size,
                   profile ?? .Defaults.sdr,
                   payload)
        }
    }
}
