//
//  ControlsView.swift
//  SwiftEDRExample
//
//  Created by Jesse Hemingway on 9/11/26.
//

import SwiftUI
import SwiftEDR

struct ControlsView: View {
    struct Config {
        var objectCount: CGFloat = 1600
        var objectSize: CGFloat = 0.135
        var colorAlpha: CGFloat = 0.125
        var backgroundLevel: CGFloat = 0.03
        var isSwiftVisible: Bool = false
        var isShowingHero: Bool = false
        var isAnimating: Bool = false

        static let `default` = Self()
    }

    @Binding var profile: Profile
    @Binding var config: Config

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass: UserInterfaceSizeClass?

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                compactGlobalControls
            } else {
                standardGlobalControls
            }
        }

    }
}

private extension ControlsView {

    var standardGlobalControls: some View {
        Grid(alignment: .topTrailing, horizontalSpacing: 16, verticalSpacing: 4) {
            GridRow {
                objectCountControl
                objectSizeControl
                objectOpacityControl
            }
            GridRow {
                bloomRadiusControl
                bloomIntensityControl
                bloomThresholdControl
            }
            GridRow(alignment: .bottom) {
                backgroundLevelControl
                HStack {
                }
                bloomKneeWidthControl
            }
        }
    }

    var compactGlobalControls: some View {
        VStack(spacing: 4) {
            objectCountControl
            objectSizeControl
            objectOpacityControl
            bloomRadiusControl
            bloomIntensityControl
            bloomThresholdControl
        }
    }

    var objectCountControl: some View {
        attributeSlider {
            Text("Draw Count: \(Int(config.objectCount))")
            Slider(value: $config.objectCount, in: 50...5000)
        } reset: {
            config.objectCount = Config.default.objectCount
        }
    }

    var objectSizeControl: some View {
        attributeSlider {
            Text("Draw Size: \(formatter.string(from: config.objectSize as NSNumber)!)")
            Slider(value: $config.objectSize, in: 0.05...1)
        } reset: {
            config.objectSize = Config.default.objectSize
        }
    }

    var objectOpacityControl: some View {
        attributeSlider {
            Text("Draw Opacity: \(formatter.string(from: config.colorAlpha as NSNumber)!)")
            Slider(value: $config.colorAlpha, in: 0...1)
        } reset: {
            config.colorAlpha = Config.default.colorAlpha
        }
    }

    var backgroundLevelControl: some View {
        attributeSlider {
            Text("Background White")
            Slider(value: $config.backgroundLevel, in: 0.0...2)
        } reset: {
            config.backgroundLevel = Config.default.backgroundLevel
        }
    }

    var bloomRadiusControl: some View {
        attributeSlider {
            Text("Bloom Radius: \(formatter.string(from: profile.bloom.radius as NSNumber)!)")
            Slider(value: $profile.bloom.radius, in: 0...0.25)
        } reset: {
            profile.bloom.radius = 0.035
        }
    }

    var bloomIntensityControl: some View {
        attributeSlider {
            Text("Bloom Intensity: \(formatter.string(from: profile.bloom.intensity as NSNumber)!)")
            Slider(value: $profile.bloom.intensity, in: 0...10)
        } reset: {
            profile.bloom.intensity = 1.0
        }
    }

    var bloomThresholdControl: some View {
        attributeSlider {
            Text("Bloom Thresh: \(formatter.string(from: profile.bloom.threshold as NSNumber)!)")
            Slider(value: $profile.bloom.threshold, in: 0.1...2)
        } reset: {
            profile.bloom.threshold = profile.mode == .hdr ? 1 : 0.9
        }
    }

    var bloomKneeWidthControl: some View {
        attributeSlider {
            Text("Bloom Knee: \(formatter.string(from: profile.bloom.kneeWidth as NSNumber)!)")
            Slider(value: $profile.bloom.kneeWidth, in: 0.01...1)
        } reset: {
            profile.bloom.kneeWidth = 0.1
        }
    }

    func attributeSlider<Content: View>(@ViewBuilder content: () -> Content,
                                        reset: @escaping () -> Void) -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            Button {
                reset()
            } label: {
                Image(systemName: "arrow.counterclockwise.circle.fill")
            }
            .font(.title)
        }
    }

    private var formatter: NumberFormatter { NumberFormatter.fractional3 }
}

#Preview {
    @Previewable @State var profile: Profile = .Defaults.hdrBloom
    @Previewable @State var config: ControlsView.Config = .init()
    ControlsView(profile: $profile, config: $config)
}
