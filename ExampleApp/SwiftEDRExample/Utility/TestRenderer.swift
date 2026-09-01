//
//  TestRenderer.swift
//  EDRTestLab
//
//  Created by Jesse Hemingway on 8/27/26.
//

import SwiftUI
import SwiftEDR

struct TestRenderer {
    let context: GraphicsContext
    let size: CGSize
    let picture: Picture
    let time: TimeInterval
    let colorAlpha: CGFloat
    let objectCount: Int
    let objectSize: CGFloat

    init(ctx: GraphicsContext, size: CGSize, picture: Picture, time: TimeInterval,
         colorAlpha: CGFloat, objectCount: Int, objectSize: CGFloat = 50) {
        self.context = ctx
        self.size = size
        self.picture = picture
        self.time = time
        self.colorAlpha = colorAlpha
        self.objectCount = objectCount
        self.objectSize = objectSize
    }

    func render() {
        let objectsPerColor = objectCount / colors.count
        let heightPerColor = (size.height - objectSize) / CGFloat(colors.count + 1)
        let viewRadius = min(size.width, size.height) / 2
        let objectSize = self.objectSize * viewRadius
        let colorSteps = colors.reversed().enumerated()

        for (colorIndex, color) in colorSteps {
            let uColor = CGFloat(colorIndex) / CGFloat(colors.count)
            let yBase = heightPerColor / 2 + uColor * size.height

            for objectIndex in 0..<objectsPerColor {
                let uObject = CGFloat(objectIndex) / CGFloat(objectsPerColor)

                let radius = (0.7 + sin((uObject + time * 0.2) * 2 * .pi) * 0.3) * objectSize / 2

                let origin = CGPoint(x: size.width * uObject,
                                     y: yBase + heightPerColor * cos((uObject - 0.3 * sin((uColor + time) * .pi / 20)) * 2 * .pi * 4))

                let rect = CGRect(origin: .init(x: origin.x - radius,
                                                y: origin.y - radius),
                                  size: .init(width: radius * 2, height: radius * 2))

                context.fill(Path(ellipseIn: rect), with: .color(color))
            }
        }
    }
}

private extension TestRenderer {
    var colors: [Color] {
        let rawColors: [[CGFloat]] = (0..<8).map { index in
            let uIndex = CGFloat(index) / 8
            let basePhase = 2 * .pi * uIndex
            let frequency = 0.1 + uIndex * 0.05
            let timePhase = 2 * .pi * time * frequency

            let phaseWobble: CGFloat = 0.12 + sin(timePhase * 0.01 + basePhase) * 0.12 // (1 - 2 * phaseSpread)

            return [0.6 + 0.4 * sin(timePhase),
                    0.6 + 0.4 * sin(timePhase + phaseWobble * 2 * .pi),
                    0.6 + 0.4 * sin(timePhase - phaseWobble * 2 * .pi),
                    colorAlpha]
        }

        return picture.rgbColors(rawColors)
    }
}
