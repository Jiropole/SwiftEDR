//
//  HeroOverlay.swift
//  SwiftEDRExample
//
//  Created by Jesse Hemingway on 9/13/26.
//

import SwiftUI
import SwiftEDR

struct HeroOverlay: View {
    let elapsed: CGFloat

    @Environment(\.edrProfile) private var profile
    @Environment(\.edrHeadroom) private var headroom

    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                subImage(offset: 0)
                subImage(offset: 0.25)
                subImage(offset: 0.5)
                subImage(offset: 0.75)
            }
            .padding(.horizontal, 48)

            Text("EDRModifier on an arbitrary view\nHeadroom: \(headroom.current, specifier: "%.2f") / \(headroom.potential, specifier: "%.2f")")
                .multilineTextAlignment(.center)
                .font(.headline.bold().italic())
                .foregroundStyle(colorAtElapsed(elapsed))
        }
    }

    func subImage(offset: CGFloat) -> some View {
        let stepElapsed = elapsed + offset
        return Image(systemName: "progress.indicator",
                     variableValue: fmod(stepElapsed / 4, 1))
        .resizable()
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .fontWeight(.bold)
        .foregroundStyle(colorAtElapsed(stepElapsed))
        .rotationEffect(.radians(.pi / 8 * offset + .pi * offset))
    }

    func colorAtElapsed(_ elapsed: CGFloat) -> Color {
        profile.hsvColor([
            fmod(elapsed / 8, 1), // hue
            0.8 + 0.2 * sin(elapsed * 2 * .pi / 3), // saturation
            (0.4 + 0.3 * sin(elapsed * 2 * .pi / 5)) * (1 + headroom.current) / 2, // value/brightness
            1.0 // opacity
        ]).headroom(headroom.potential)
    }
}
