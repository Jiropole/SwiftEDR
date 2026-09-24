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
    let palette: Palette
    let elapsed: TimeInterval
    let colorAlpha: CGFloat
    let objectCount: Int
    let objectSize: CGFloat

    init(ctx: GraphicsContext, size: CGSize, palette: Palette,
         elapsed: TimeInterval, colorAlpha: CGFloat,
         objectCount: Int, objectSize: CGFloat = 50) {
        self.context = ctx
        self.size = size
        self.palette = palette
        self.elapsed = elapsed
        self.colorAlpha = colorAlpha
        self.objectCount = objectCount
        self.objectSize = objectSize
    }

    func render() {
        var context = self.context
        context.blendMode = .plusLighter

        let colors = hsvColors
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

                let radius = (0.7 + sin((uObject + elapsed * 0.2) * 2 * .pi) * 0.3) * objectSize / 2

                let origin = CGPoint(x: size.width * uObject,
                                     y: yBase + heightPerColor * cos((uObject - 0.3 * sin((uColor + elapsed) * .pi / 20)) * 2 * .pi * 4))

                let rect = CGRect(origin: .init(x: origin.x - radius,
                                                y: origin.y - radius),
                                  size: .init(width: radius * 2, height: radius * 2))

                context.fill(Path(ellipseIn: rect), with: .color(color))
            }
        }
    }
}

private extension TestRenderer {

    var rgbColors: [Color] {
        func osc(_ angle: CGFloat) -> CGFloat {
            pow((1 + sin(angle)) / 2, 3)
        }

        let rawColors: [[CGFloat]] = (0..<8).map { index in
            let uIndex = CGFloat(index) / 8
            let stepPhase = 2 * .pi * uIndex
            let frequency = 0.1 + uIndex * 0.05
            let timePhase = 2 * .pi * elapsed * frequency
            let phaseWobble: CGFloat = 0.12 + sin(timePhase * 0.01 + stepPhase) * 0.12

            return [osc(timePhase),
                    osc(timePhase + phaseWobble * 2 * .pi),
                    osc(timePhase - phaseWobble * 2 * .pi),
                    colorAlpha]
        }

        return palette.rgbColors(rawColors, boost: palette.headroom.current)
    }

    var hsvColors: [Color] {
        func osc(_ angle: CGFloat) -> CGFloat {
            pow((1 + sin(angle)) / 2, 1.5)
        }
        let rawColors: [[CGFloat]] = (0..<8).map { index in
            let uIndex = CGFloat(index) / 8
            let stepPhase = 2 * .pi * uIndex
            let frequency = 0.08 + uIndex * 0.05
            let timePhase = stepPhase + 2 * .pi * elapsed * frequency
            let phaseWobble: CGFloat = 0.12 + sin(timePhase * 0.01) * 0.12

            return [fmod(uIndex + elapsed * 0.08, 1),
                    0.6 + 0.4 * sin(timePhase + phaseWobble * 2 * .pi),
                    osc(timePhase),
                    colorAlpha]
        }

        return palette.hsvColors(rawColors, boost: palette.headroom.current)
    }
}
