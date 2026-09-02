//
//  ContentView.swift
//  SwiftEDRExample
//
//  Created by Jesse Hemingway on 8/27/26.
//

import SwiftUI
import SwiftEDR

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass: UserInterfaceSizeClass?

    @State private var profile: Profile = .Defaults.edrBloom
    @State private var config: Config = .default
    @State private var isAnimating: Bool = true
    @State private var isShowingHero: Bool = false
    @State private var options: Diagnostics = []
    @State private var startDate: Date = Date()
    @State private var pauseDate: Date = Date()

    private var formatter: NumberFormatter { NumberFormatter.fractional3 }

    var body: some View {
        VStack(spacing: 16) {
            Picker("Dynamic Range", selection: .init(get: { profile.mode },
                                                     set: { profile.mode = $0 })) {
                Text("SDR").tag(Profile.Mode.sdr)
                Text("EDR").tag(Profile.Mode.edr)
                Text("HDR").tag(Profile.Mode.hdr)
            }
            .pickerStyle(.segmented)

            TimelineView(.animation(minimumInterval: 1 / 30.0, paused: !isAnimating)) { timeline in
                let elapsed = timeline.date.timeIntervalSince(startDate)
                VStack(spacing: 8) {
                    if config.isSwiftVisible {
                        swiftCanvasView(elapsed: elapsed)
                            .background(Color(white: config.backgroundLevel))
                            .clipped()
                    }

                    edrCanvasViewWithPicture(profile, elapsed: elapsed)
                        .background(Color(white: config.backgroundLevel))
                        .clipped()
                }
                .overlay {
                    if isShowingHero {
                        heroImage(elapsed: elapsed)
                    }
                }
            }
            .overlay(alignment: .topTrailing) {
                optionsControls
            }

            Group {
                if horizontalSizeClass == .compact {
                    compactGlobalControls
                } else {
                    standardGlobalControls
                }
            }
            .padding(.horizontal, 16)
        }
        .onChange(of: isAnimating, { _, newValue in
            if newValue {
                startDate += Date().timeIntervalSince(pauseDate)
            } else {
                pauseDate = Date()
            }
        })
        .padding(.bottom, 8)
        .background(Color.white.opacity(0.2))
        .preferredColorScheme(.dark)
    }
}

// MARK: Canvas Examples

private extension ContentView {
    func edrCanvasViewWithPicture(_ profile: Profile, elapsed: TimeInterval) -> some View {
        EDRCanvas(isOpaque: true) { context, size, profile in
            TestRenderer(ctx: context,
                         size: size,
                         profile: profile,
                         elapsed: elapsed,
                         colorAlpha: config.colorAlpha,
                         objectCount: Int(config.objectCount),
                         objectSize: config.objectSize)
            .render()
        }
                  .modifier(EDRModifier(profile: profile, options: options))
    }

    func swiftCanvasView(elapsed: TimeInterval) -> some View {
        Canvas { context, size in
            TestRenderer(ctx: context,
                         size: size,
                         profile: .Defaults.sdr,
                         elapsed: elapsed,
                         colorAlpha: config.colorAlpha,
                         objectCount: Int(config.objectCount),
                         objectSize: config.objectSize)
            .render()
        }
    }

    func heroImage(elapsed: TimeInterval) -> some View {
        func subImage(offset: CGFloat) -> some View {
            let stepElapsed = elapsed + offset
            return Image(systemName: "progress.indicator",
                         variableValue: fmod(stepElapsed / 4, 1))
            .resizable()
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 500)
            .fontWeight(.bold)
            .foregroundStyle(profile.hsvColor([
                fmod(elapsed / 4 + offset / 8, 1), // hue
                0.7 + 0.5 * sin(stepElapsed * 2 * .pi / 11), // saturation
                1.25, // value/brightness
                1.0 // opacity
            ]))
            .rotationEffect(.radians(.pi / 8 * offset + .pi * offset))
        }

        return VStack(spacing: 32) {
            ZStack {
                subImage(offset: -0.5)
                subImage(offset: 0)
                subImage(offset: 0.5)
            }
            .padding(.horizontal, 48)

            Text("Applying EDRModifier to an arbitrary view")
                .font(.headline.bold().italic())
                .foregroundStyle(profile.hsvColor([
                    fmod(elapsed / 8, 1), // hue
                    0.7 + 0.5 * sin(elapsed * 2 * .pi / 11), // saturation
                    1.2, // value/brightness
                    1.0 // opacity
                ]))
        }
        .padding(24)
        .modifier(EDRModifier(profile: profile, options: options))
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .padding(8)
    }
}

// MARK: Global Controls

private extension ContentView {
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
            GridRow {
                backgroundLevelControl
                Color.clear.frame(width: 1, height: 1)
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

    var optionsControls: some View {
        VStack(alignment: .trailing) {
            HStack(spacing: 12) {
                Button {
                    options.isBloomHighlightsOnly.toggle()
                } label: {
                    Image(systemName: "ladybug.fill")
                        .foregroundStyle(options.isBloomHighlightsOnly ? Color.accentColor : Color.white)
                }
                Button {
                    isShowingHero.toggle()
                } label: {
                    Image(systemName: "photo")
                        .foregroundStyle(isShowingHero ? Color.accentColor : Color.white)
                }
                Button {
                    switch profile.mode {
                    case .sdr:
                        profile = .Defaults.sdrBloom
                    case .edr:
                        profile = .Defaults.edrBloom
                    case .hdr:
                        profile = .Defaults.hdrBloom
                    }
                    config = .init()
                } label: {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                }
                Button {
                    isAnimating.toggle()
                } label: {
                    Image(systemName: isAnimating ? "pause.fill" : "play.fill")
                }

            }
            .font(.title)
            .foregroundStyle(Color.white)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(4)
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
            profile.bloom.radius = 0.05
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
            profile.bloom.kneeWidth = 0.9
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
}

// MARK: Model

private extension ContentView {
    struct Config {
        var objectCount: CGFloat = 1600
        var objectSize: CGFloat = 0.135
        var colorAlpha: CGFloat = 0.125
        var backgroundLevel: CGFloat = 0.03
        var isBloomEnabled: Bool = false
        var isSwiftVisible: Bool = false

        static let `default` = Self()
    }
}


#Preview {
    ContentView()
}
