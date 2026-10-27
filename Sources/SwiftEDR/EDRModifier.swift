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

    /// The follower publishes changes to headroom attributes.
    @State private var headroomFollower: HeadroomFollower = .init()

    /// Initialize a modifier for a given profile.
    /// - Parameters:
    ///   - profile: Selects an EDR Profile to be applied to `content`.
    public init(profile: Profile) {
        self.profile = profile
    }

    public func body(content: Content) -> some View {
        let palette = Palette(profile: profile,
                              headroom: headroomFollower.headroom.headroomForProfile(profile))
        return content
            // Ensure content opacity is consistent between display or bitmap rendering targets.
            .drawingGroup(opaque: false, colorMode: profile.renderMode)

            // Add any bloom effect.
            .modifier(BloomModifier())

            // Assert any current request for elevated headroom, which can be disrupted by shaders in the pipeline.
            .modifier(HeadroomAsserter())

            // Ensure content opacity and effects are consistent between display or bitmap rendering targets.
            .drawingGroup(opaque: false, colorMode: profile.renderMode)

            // Adjust requested dynamic range according to mode and options.
            .allowedDynamicRange(profile.dynamicRange)

#if os(visionOS)
            // Cue to deemphasize surrounding brightness on VisionOS.
            .preferredSurroundingsEffect(profile.mode == .hdr ? .dark : nil)
#endif

            // Ensure headroom is updated when attributes are likely to change (mainly for Mac).
            .onChange(of: profile) { oldValue, newValue in
                headroomFollower.prime()
            }

            // Add profile and headroom to environment.
            .environment(\.edrPalette, palette)
    }
}
