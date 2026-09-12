//
//  HeadroomPoller.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/9/26.
//


import SwiftUI

/// Helper class that polls the current screen's headroom info and updates `headroom`.
/// For performance reasons, it may be unwise to use high polling frequencies.
@Observable
public final class HeadroomPoller {
    private let profile: Profile

    // Fluctuates according to changing screen characteristics.
    public var headroom: Headroom

    @ObservationIgnored
    private var timer: Timer? = nil

    /// `pollfrequency` = 0 disables polling.
    public init(profile: Profile, pollfrequency: TimeInterval = 1.0) {
        self.profile = profile

        // Initialize with current screen headroom.
        self.headroom = Self.supportedHeadroom(forMode: profile.mode)
        print("Mode \(profile.mode): \(headroom)")
        guard pollfrequency > 0 else { return }

        // If polling is enabled, start a poll timer.
        let interval: TimeInterval = 1.0 / pollfrequency
        self.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            let headroom = Self.supportedHeadroom(forMode: self.profile.mode)
            guard headroom != self.headroom else { return }

            print("Mode \(self.profile.mode): \(headroom)")
            self.headroom = headroom
        }

        // Try to keep the overhead low.
        self.timer?.tolerance = interval * 0.5
    }

    deinit {
        self.timer?.invalidate()
    }

    private static func supportedHeadroom(forMode mode: Profile.Mode) -> Headroom {
        mode == .hdr ? NativeScreen.headroom ?? .init() : .init()
    }
}
