//
//  HeadroomMonitor.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/21/26.
//

import Foundation
#if os(iOS) || os(visionOS)
import UIKit
#endif

/// Monitors changes to active screen headroom values.
public actor HeadroomMonitor {
    /// Using this singleton is recommended in order to minimize polling and notification subscription overhead.
    public static let shared = HeadroomMonitor()

    /// Multicaster publishing changes to headroom.
    let multicaster: Multicaster = .init(Headroom())

    // Used for backoff polling of headroom.
    private var repeater: BackoffRepeater?
    // Used in iOS and MacOS for respective notifications.
    private var notificationTask: Task<Void, Never>?

    /// Initialize a headroom monitor.
    /// `delayRange` controls the minimum and maximum poll frequency, and 0 disables polling.
    public init(delayRange: ClosedRange<TimeInterval> = 0.05...1.0) {
#if os(iOS)
        // In iOS, there is no way to be notified when headroom changes,
        // and on MacOS we miss changes in potential headroom without polling.
        // As a workaround, use a backoff repeater to poll for changes.
        self.repeater = BackoffRepeater(delayRange: delayRange)
        Task { [weak self] in
            await self?.monitorRepeater()
        }
        // For iOS, headroom is also likely to change when brightness or focus changes.
        Task {
            await monitorNotification(UIScreen.brightnessDidChangeNotification)
            await monitorNotification(UIWindow.didBecomeKeyNotification)
        }
#elseif os(macOS)
        // In AppKit there is a convenient notification whenever current headroom changes.
        // We also monitor focus as not all cases are caught by the screen notification.
        Task {
            await monitorNotification(NativeApplication.didChangeScreenParametersNotification)
            await monitorNotification(NativeApplication.didBecomeActiveNotification)
        }
#endif
        // And for VisionOS, there is no changing headroom, to my knowledge.
    }

    /// Temporarily speeds up responsiveness when a changing environment is predicted.
    public func prime() {
        Task { [weak self] in
            await _ = self?.updateHeadroom()
            await self?.monitorRepeater(speedUp: true)
        }
    }

    isolated deinit {
        notificationTask?.cancel()
    }
}

private extension HeadroomMonitor {
    /// Conditionally updates headroom by querying system properties, returning true if the value changed.
    private func updateHeadroom() async -> Bool {
        let headroom = (await Headroom.readHeadroom()) ?? .init()
        guard await headroom != self.multicaster.value else { return false }
        await self.multicaster.updateValue(headroom)
        return true
    }

    func monitorNotification(_ name: Notification.Name) {
        self.notificationTask = Task { [weak self] in
            let sequence = NotificationCenter.default
                .notifications(named: name)
            for await _ in sequence {
                guard let self, !Task.isCancelled else { return }
                _ = await updateHeadroom()
            }
        }
    }

    func monitorRepeater(speedUp: Bool = false) async {
        await repeater?.execute(speedUp: speedUp) { [weak self] in
            // Don't backoff so long as values keep changing.
            return await self?.updateHeadroom() ?? false
        }
    }
}
