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
    let profile: Profile
    let headroom: Headroom
    let elapsed: TimeInterval
    let colorAlpha: CGFloat
    let objectCount: Int
    let objectSize: CGFloat

    init(ctx: GraphicsContext, size: CGSize, profile: Profile, headroom: Headroom,
         elapsed: TimeInterval, colorAlpha: CGFloat, objectCount: Int, objectSize: CGFloat = 50) {
        self.context = ctx
        self.size = size
        self.profile = profile
        self.headroom = headroom
        self.elapsed = elapsed
        self.colorAlpha = colorAlpha
        self.objectCount = objectCount
        self.objectSize = objectSize
    }

    func render() {
        var context = self.context
        context.blendMode = .plusLighter

        let colors = rgbColors
        let objectsPerColor = objectCount / rgbColors.count
        let heightPerColor = (size.height - objectSize) / CGFloat(rgbColors.count + 1)
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
    func osc(_ angle: CGFloat) -> CGFloat {
        pow((1 + sin(angle)) / 2, 3) * headroom.current
    }

    var rgbColors: [Color] {

        let rawColors: [[CGFloat]] = (0..<8).map { index in
            let uIndex = CGFloat(index) / 8
            let basePhase = 2 * .pi * uIndex
            let frequency = 0.1 + uIndex * 0.05
            let timePhase = 2 * .pi * elapsed * frequency

            let phaseWobble: CGFloat = 0.12 + sin(timePhase * 0.01 + basePhase) * 0.12

            return [osc(timePhase),
                    osc(timePhase + phaseWobble * 2 * .pi),
                    osc(timePhase - phaseWobble * 2 * .pi),
                    colorAlpha]
        }

        return profile.rgbColors(rawColors).map { $0.headroom(headroom.potential) }
    }

    var hsvColors: [Color] {
        let rawColors: [[CGFloat]] = (0..<8).map { index in
            let uIndex = CGFloat(index) / 8
            let basePhase = 2 * .pi * uIndex
            let frequency = 0.1 + uIndex * 0.05
            let timePhase = 2 * .pi * elapsed * frequency

            let phaseWobble: CGFloat = 0.12 + sin(timePhase * 0.01 + basePhase) * 0.12

            return [0.5 + 0.5 * sin(timePhase),
                    0.5 + 0.5 * sin(timePhase + phaseWobble * 2 * .pi),
                    osc(timePhase),
                    colorAlpha]
        }

        return profile.hsvColors(rawColors).map { $0.headroom(headroom.potential) }
    }
}
