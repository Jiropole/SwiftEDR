//
//  HeadroomPoller.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/9/26.
//

import SwiftUI

/// Helper class that polls the current screen's headroom info and updates `headroom`.
@Observable
public final class HeadroomFollower {
    private let profile: Profile

    // Fluctuates according to changing screen characteristics.
    public var headroom: Headroom

    @ObservationIgnored
    private var repeater: BackoffRepeater? = nil

    @ObservationIgnored
    private var lastChange: Date = .distantPast

    /// Initialize a poller for the given profile.
    /// `pollfrequency` controls the maximum poll frequency, and 0 disables polling.
    public init(profile: Profile, pollfrequency: TimeInterval = 1.0) {
        self.profile = profile

        // Initialize with current screen headroom.
        self.headroom = Self.supportedHeadroomForProfile(profile)
//        print("Mode \(profile.mode): \(headroom)")
        guard pollfrequency > 0 else { return }

#if os(iOS)
        // In iOS, there is no way to be notified when headroom changes.
        // However, headroom is likely to change when brightness changes.
        NotificationCenter.default
            .addObserver(self, selector: #selector(updateHeadroom),
                         name: UIScreen.brightnessDidChangeNotification, object: nil)

        // As a fallback, we use a backoff repeater to poll for changes.
        let maxInterval: TimeInterval = 1.0 / pollfrequency
        self.repeater = BackoffRepeater(delayRange: 0.04...maxInterval)
        self.repeater?.execute { [weak self] in
            guard let self = self else { return true }
            let headroom = Self.supportedHeadroomForProfile(profile)
            if self.headroom != headroom {
                self.headroom = headroom
                // Don't backoff so long as values keep changing.
                return false
            } else {
                return true
            }
        }

#elseif os(macOS)
        // In AppKit there is a convenient notification whenever headroom changes.
        NotificationCenter.default
            .addObserver(self, selector: #selector(updateHeadroom),
                         name: NativeApplication.didChangeScreenParametersNotification, object: nil)
#endif
    }

    private static func supportedHeadroomForProfile(_ profile: Profile) -> Headroom {
#if os(visionOS)
        var headroom = profile.mode == .hdr ? Headroom(current: 10, potential: 10, reference: 0) : .init()
#else
        var headroom = profile.mode == .hdr ? Headroom.readHeadroom() ?? .init() : .init()
#endif
        return Headroom(current: min(headroom.current, profile.maxHeadroom),
                        potential: min(headroom.current, profile.maxHeadroom),
                        reference: min(headroom.current, profile.maxHeadroom))
    }

    @objc private func updateHeadroom(notification: Notification? = nil) {
        let headroom = Self.supportedHeadroomForProfile(profile)
        guard headroom != self.headroom else { return }
//        print("Mode \(profile.mode): \(headroom)")
        self.headroom = headroom
    }
}
