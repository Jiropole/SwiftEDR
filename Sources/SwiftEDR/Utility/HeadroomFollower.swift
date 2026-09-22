//
//  HeadroomFollower.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/9/26.
//

import SwiftUI

/// Observable class that publishes updates to the active screen `headroom`.
/// Can be concurrently instantiated without increasing monitoring overhead.
@MainActor @Observable
public final class HeadroomFollower {
    /// The active profile. Reported headroom may be capped according to the profile.
    public let profile: Profile

    /// Fluctuates according to changing screen characteristics.
    public var headroom: Headroom

    /// Initialize a poller for the given profile.
    /// `pollfrequency` controls the maximum poll frequency, and 0 disables polling.
    public init(profile: Profile) {
        self.profile = profile
        self.headroom = Headroom.readHeadroom()?.headroomForProfile(profile) ?? .init()

        Task { [weak self] in
            await HeadroomMonitor.shared.speedUp()
            for await headroom in HeadroomMonitor.shared.headroomChannel {
                guard let self, !Task.isCancelled else { return }
                self.updateHeadroom(headroom)
            }
        }
    }

    private func updateHeadroom(_ headroom: Headroom) {
        let cappedHeadroom = headroom.headroomForProfile(profile)
        guard cappedHeadroom != self.headroom else { return }
        self.headroom = cappedHeadroom
    }
}
