//
//  EDRModifier.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 8/31/26.
//

import SwiftUI

/// Applies EDR (extended dynamic range) color precision and display to the view content.
public struct EDRModifier: ViewModifier {
    
    /// EDR profile configuration.
    private let profile: Profile

    /// The follower will publish changes to headroom attributes.
    private let headroomFollower: HeadroomFollower

    /// Initialize a modifier for a given profile.
    /// - Parameters:
    ///   - profile: Selects an EDR Profile to be applied to `content`.
    ///   - pollFrequency: Controls the slowest rate the `edrHeadroom` environment value may updated, in Hz. High frequency polling is not recommended. Default: 1Hz. If high frequency headroom updates are required, EDRCanvas is the better choice.
    public init(profile: Profile, pollFrequency: CGFloat = 1.0) {
        self.profile = profile
        self.headroomFollower = HeadroomFollower(profile: profile, pollfrequency: pollFrequency)
    }

    public func body(content: Content) -> some View {
        let palette = Palette(profile: profile, headroom: headroomFollower.headroom)
        return content
            // Add any bloom effect.
            .modifier(BloomModifier())

            // Add any tone mapping effect (needs work).
            .modifier(ToneMapModifier())

            // Assert any current request for elevated headroom, which can be disrupted by shaders in the pipeline.
            .modifier(HeadroomAsserter())

            // Adjust requested dynamic range according to mode and options.
            .allowedDynamicRange(profile.relativeDynamicRange)

#if os(visionOS)
            // Cue to deemphasize surrounding brightness on VisionOS.
            .preferredSurroundingsEffect(profile.mode == .hdr ? .dark : nil)
#endif

            // Add profile and headroom to environment.
            .environment(\.edrPalette, palette)
    }
}
