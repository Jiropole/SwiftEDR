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

    @Environment(\.palette) private var palette

    var body: some View {
        ZStack {
            Group {
                subImage(offset: 0)
                subImage(offset: 0.25)
                subImage(offset: 0.5)
                subImage(offset: 0.75)
            }
//            .blendMode(.plusLighter)
            .compositingGroup()
        }
        .overlay(alignment: .bottom) {
            /// Use a Shape, which can handle HDR colors, and then mask it.
            metricsView.opacity(0)
                .padding(8)
                .background(Color.black.opacity(0.75))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    colorAtElapsed(elapsed)
                        .mask {
                            Text("Headroom: \(palette.headroom.current, specifier: "%.2f") / \(palette.headroom.potential, specifier: "%.2f")\nAdaptive threshold: \(palette.effectiveBloomThreshold, specifier: "%.2f")")
                                .multilineTextAlignment(.center)
                                .font(.footnote.italic())
                        }
                }
        }
        .padding(.horizontal, 48)
    }

    var metricsView: some View {
        Text("Headroom: \(palette.headroom.current, specifier: "%.2f") / \(palette.headroom.potential, specifier: "%.2f")\nAdaptive threshold: \(palette.effectiveBloomThreshold, specifier: "%.2f")")
            .multilineTextAlignment(.center)
            .font(.footnote.italic())
    }

    func subImage(offset: CGFloat) -> some View {
        let stepElapsed = elapsed + offset
        /// Use a Shape, which can handle HDR colors, and then mask it.
        return Circle()
            .mask {
                Image(systemName: "progress.indicator", variableValue: fmod(stepElapsed / 4, 1))
                    .resizable().scaledToFit()
            }
            .frame(maxWidth: 500)
            .fontWeight(.bold)
            .foregroundStyle(colorAtElapsed(stepElapsed))
            .allowedDynamicRange(.high)
            .rotationEffect(.radians(.pi / 8 * offset + .pi * offset))
    }

    func colorAtElapsed(_ elapsed: CGFloat) -> Color {
        palette.hsvColor([
            fmod(elapsed / 8, 1), // hue
            0.8 + 0.2 * sin(elapsed * 2 * .pi / 3), // saturation
            (0.6 + 0.4 * sin(elapsed * 2 * .pi / 5)) * palette.headroom.current, // value/brightness
            1.0 // opacity
        ])
    }
}
