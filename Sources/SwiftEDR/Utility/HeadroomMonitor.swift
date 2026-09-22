//
//  HeadroomMonitor.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/21/26.
//

import SwiftUI
import Combine
import AsyncAlgorithms

/// Monitors changes to active screen headroom values.
public actor HeadroomMonitor {
    /// Using this singleton is recommended in order to minimize polling and notification subscription overhead.
    public static let shared = HeadroomMonitor()

    /// Async channel publishing changes to headroom.
    let headroomChannel: AsyncChannel<Headroom> = .init()

    /// Fluctuates according to changing screen characteristics.
    public private(set) var headroom: Headroom = .init()

    private var repeater: BackoffRepeater?
    private var notificationTask: Task<Void, Never>?

    /// Initialize a headroom monitor.
    /// `delayRange` controls the minimum and maximum poll frequency, and 0 disables polling.
    public init(delayRange: ClosedRange<TimeInterval> = 0.05...1.0) {
#if os(iOS)
        // In iOS, there is no way to be notified when headroom changes.
        // As a workaround, use a backoff repeater to poll for changes.
        self.repeater = BackoffRepeater(delayRange: delayRange)
        Task {
            await monitorRepeater()
        }
        // Secondly, headroom is likely to change when brightness changes.
        Task {
            await monitorNotification(UIScreen.brightnessDidChangeNotification)
        }
#elseif os(macOS)
        // In AppKit there is a convenient notification whenever headroom changes.
        Task {
            await monitorNotification(NativeApplication.didChangeScreenParametersNotification)
        }
#endif
        // And for VisionOS, there is no changing headroom, to my knowledge.
    }

    /// Cause the monitor to jump up to maximum frequency.
    public func speedUp() {
        Task {
            await monitorRepeater(speedUp: true)
        }
    }

    /// Conditionally updates headroom, returning true if the value changed.
    private func updateHeadroom() async -> Bool {
        let headroom = (await Headroom.readHeadroom()) ?? .init()
        guard headroom != self.headroom else { return false }
        self.headroom = headroom
        await headroomChannel.send(headroom)
        return true
    }

    private func monitorNotification(_ name: Notification.Name) {
        self.notificationTask = Task { [weak self] in
            let sequence = NotificationCenter.default
                .notifications(named: name)
            for await _ in sequence {
                guard let self, !Task.isCancelled else { return }
                _ = await self.updateHeadroom()
            }
        }
    }

    private func monitorRepeater(speedUp: Bool = false) async {
        await repeater?.execute(speedUp: speedUp) { [weak self] in
            // Don't backoff so long as values keep changing.
            return await self?.updateHeadroom() ?? false
        }
    }

    isolated deinit {
        notificationTask?.cancel()
    }
}
