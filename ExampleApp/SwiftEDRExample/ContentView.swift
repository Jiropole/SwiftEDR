//
//  ContentView.swift
//  SwiftEDRExample
//
//  Created by Jesse Hemingway on 8/27/26.
//

import SwiftUI
import SwiftEDR

struct ContentView: View {
    @State private var profile: Profile = .Defaults.edrBloom
    @State private var config: ControlsView.Config = .default

    @State private var startDate: Date = Date()
    @State private var pauseDate: Date = Date()

    var body: some View {
        VStack(spacing: 8) {
            Picker("Dynamic Range", selection: .init(get: { profile.mode },
                                                     set: { profile.mode = $0 })) {
                Text("SDR-NL").tag(Profile.Mode.sdrNonlinear)
                Text("SDR").tag(Profile.Mode.sdr)
                Text("EDR").tag(Profile.Mode.edr)
                Text("HDR").tag(Profile.Mode.hdr)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)

            generativeArtView

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
    var generativeArtView: some View {
        TimelineView(.animation(minimumInterval: 1 / 30.0, paused: !config.isAnimating)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startDate)

            VStack(spacing: 8) {
                if config.isSwiftVisible {
                    swiftCanvasView(elapsed: elapsed)
                        .background(Color(white: config.backgroundLevel))
                        .clipped()
                }

                edrCanvasViewWithProfile(profile, elapsed: elapsed)
                    .background(Color(white: config.backgroundLevel))
                    .clipped()
            }
            .overlay {
                if config.isShowingHero {
                    HeroOverlay(elapsed: elapsed)
                        .modifier(EDRModifier(profile: profile))
                        .padding(24)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                        .padding(8)

                }
            }
        }
        .overlay(alignment: .topTrailing) {
            edrOptionsOverlay
        }
    }

    func edrCanvasViewWithProfile(_ profile: Profile, elapsed: TimeInterval) -> some View {
        EDRCanvas(opaque: true) { context, size, profile, headroom in
            TestRenderer(ctx: context,
                         size: size,
                         profile: profile,
                         headroom: headroom,
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
                         profile: .Defaults.sdr,
                         headroom: .init(),
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
                    profile.options.isBloomHighlightsOnly.toggle()
                } label: {
                    Image(systemName: "ladybug.fill")
                        .foregroundStyle(profile.options.isBloomHighlightsOnly ? Color.white : Color.black)
                        .font(.title)
                }
                // Button to toggle experimental tone mapping. Disabled for now.
//                Button {
//                    profile.options.isToneMapDefault.toggle()
//                } label: {
//                    Image(systemName: "camera.filters")
//                        .foregroundStyle(profile.options.isToneMapDefault ? Color.white : Color.black)
//                        .font(.title)
//                }
                // Button to toggle tone mapping.
                Button {
                    profile.options.isConstrainedHDR.toggle()
                } label: {
                    Image(systemName: "rectangle.compress.vertical")
                        .foregroundStyle(profile.options.isConstrainedHDR ? Color.white : Color.black)
                        .font(.title)
                }

                // Button to display hero overlay.
                Button {
                    config.isShowingHero.toggle()
                } label: {
                    Image(systemName: "photo")
                        .foregroundStyle(config.isShowingHero ? Color.white : Color.black)
                        .font(.title)
                }

                Button {
                    switch profile.mode {
                    case .sdr:
                        profile = .Defaults.sdrBloom
                    case .sdrNonlinear:
                        profile = .Defaults.sdrNonlinear
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
