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
    ///   - profile: Selects an EDR Profile.
    ///   - pollFrequency: Dontrols how often the `headroom` environment value is updated, in Hz. High frequency polling is not recommended. Default: 1Hz. If high frequency headroom updates are required, EDRCanvas is the better choice.
    public init(profile: Profile, pollFrequency: CGFloat = 1) {
        self.profile = profile
        self.headroomFollower = HeadroomFollower(profile: profile, pollfrequency: pollFrequency)
    }

    public func body(content: Content) -> some View {
        content
            // Add any bloom effect.
            .modifier(BloomModifier(profile: profile))

            // Add any tone mapping effect (needs work).
            .modifier(ToneMapModifier(profile: profile, headroom: headroomFollower.headroom))

            // Assert any current request for elevated headroom, which can be disrupted by shaders in the pipeline.
            .modifier(HeadroomAsserter(profile: profile, headroom: headroomFollower.headroom))

            // Adjust requested dynamic range according to mode and options.
            .allowedDynamicRange(profile.relativeDynamicRange)

            // Add profile and headroom to environment.
            .environment(\.edrProfile, profile)
            .environment(\.edrHeadroom, headroomFollower.headroom)
    }
}
