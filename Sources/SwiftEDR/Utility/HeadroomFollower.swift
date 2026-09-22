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
    /// Fluctuates according to changing screen characteristics.
    public var headroom: Headroom

    @ObservationIgnored
    private var task: Task<Void, Never>?

    public init() {
        self.headroom = Headroom.readHeadroom() ?? .init()
        Task { await startMonitor() }
    }

    private func startMonitor() async {
        self.task = Task { [weak self] in
            await HeadroomMonitor.shared.speedUp()
            for await headroom in HeadroomMonitor.shared.headroomChannel {
                guard let self, !Task.isCancelled else {
                    print("Not self or canceled: \(Task.isCancelled)")
                    return
                }
                guard headroom != self.headroom else { return }
                self.headroom = headroom
            }
        }
    }

    deinit {
        task?.cancel()
    }
}
