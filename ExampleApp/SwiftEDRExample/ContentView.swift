//
//  ContentView.swift
//  SwiftEDRExample
//
//  Created by Jesse Hemingway on 8/27/26.
//

import SwiftUI
import SwiftEDR

struct ContentView: View {
    @State private var profile: Profile = .Defaults.edr
    @State private var config: ControlsView.Config = .default

    @State private var startDate: Date = Date()
    @State private var pauseDate: Date = Date()
    @State private var selectedSource: EDRImage.Source?

    var body: some View {
        VStack(spacing: 8) {
            Picker("Dynamic Range", selection: .init(get: { profile.mode },
                                                     set: { profile.mode = $0 })) {
                Text("SDR").tag(Profile.Mode.sdr)
                Text("EDR").tag(Profile.Mode.edr)
                Text("HDR").tag(Profile.Mode.hdr)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)

            sampleContentView

            ControlsView(profile: $profile, config: $config)
                .padding(.horizontal, 16)
        }
        .onChange(of: config.isAnimating, { _, newValue in
            if newValue {
                startDate += Date().timeIntervalSince(pauseDate)
            } else {
                pauseDate = Date()
            }
        })
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.2))
        .preferredColorScheme(.dark)
    }
}

// MARK: Canvas Examples

private extension ContentView {
    var sampleContentView: some View {
        TimelineView(.animation(minimumInterval: 1 / 30.0, paused: !config.isAnimating)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startDate)

            if config.isShowingExamples {
                OtherExamplesView(elapsed: elapsed, selectedSource: $selectedSource)
                    .modifier(EDRModifier(profile: profile))
            } else {
                VStack(spacing: 8) {
                    if config.isSwiftVisible {
                        swiftCanvasView(elapsed: elapsed)
                    }

                    edrCanvasViewWithProfile(profile, elapsed: elapsed)
                }
            }
        }
        .background(Color(white: config.backgroundLevel))
        .overlay(alignment: .topTrailing) {
            edrOptionsOverlay
        }
    }

    func edrCanvasViewWithProfile(_ profile: Profile, elapsed: TimeInterval) -> some View {
        EDRCanvas(opaque: true) { context, size, palette in
            TestRenderer(ctx: context,
                         size: size,
                         palette: palette,
                         elapsed: elapsed,
                         colorAlpha: config.colorAlpha,
                         objectCount: Int(config.objectCount),
                         objectSize: config.objectSize)
            .render()
        }
        .modifier(EDRModifier(profile: profile))
    }

    func swiftCanvasView(elapsed: TimeInterval) -> some View {
        Canvas(opaque: true) { context, size in
            TestRenderer(ctx: context,
                         size: size,
                         palette: .init(profile: profile, headroom: .init()),
                         elapsed: elapsed,
                         colorAlpha: config.colorAlpha,
                         objectCount: Int(config.objectCount),
                         objectSize: config.objectSize)
            .render()
        }
    }

    var edrOptionsOverlay: some View {
        VStack(alignment: .trailing) {
            HStack(spacing: 12) {
                // Button to toggle bloom debugging.
                Button {
                    profile.options.isBloomSolo.toggle()
                } label: {
                    Image(systemName: "ladybug.fill")
                        .foregroundStyle(profile.options.isBloomSolo ? Color.white : Color.black)
                        .font(.title3)
                }

                // Button to toggle bloom mode.
                Button {
                    profile.bloom.mode = profile.bloom.mode == .color ? .luminance: .color
                } label: {
                    Image(systemName: "circle.hexagonpath.fill")
                        .foregroundStyle(profile.bloom.mode == .color ? Color.white : Color.black)
                        .font(.title3)
                }

                // Button to toggle constrained HDR.
                Button {
                    profile.options.isConstrainedHDR.toggle()
                } label: {
                    Image(systemName: "rectangle.compress.vertical")
                        .foregroundStyle(profile.options.isConstrainedHDR ? Color.white : Color.black)
                        .font(.title3)
                }

                // Button to toggle linear color space.
                Button {
                    profile.options.isLinearColorSpace.toggle()
                } label: {
                    Image(systemName: "righttriangle.fill")
                        .foregroundStyle(profile.options.isLinearColorSpace ? Color.white : Color.black)
                        .font(.title3)
                }

                // Button to display hero overlay.
                Button {
                    config.isShowingExamples.toggle()
                } label: {
                    Image(systemName: "photo")
                        .foregroundStyle(config.isShowingExamples ? Color.white : Color.black)
                        .font(.title3)
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
                        .font(.title)
                }
                Button {
                    config.isAnimating.toggle()
                } label: {
                    Image(systemName: config.isAnimating ? "pause.fill" : "play.fill")
                        .font(.title)
                }
            }
            .foregroundStyle(Color.white)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(4)
    }
}

#Preview {
    ContentView()
}
