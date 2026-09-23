//
//  HeadroomFollower.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/9/26.
//

import SwiftUI
import Combine

/// Observable class that publishes updates to the active screen `headroom`.
/// Can be concurrently instantiated without increasing monitoring overhead.
@MainActor @Observable
public final class HeadroomFollower {
    /// Fluctuates according to changing screen characteristics.
    public var headroom: Headroom

    private let subscriptionID: UUID = .init()

    public init() {
        self.headroom = Headroom.readHeadroom() ?? .init()
        Task { [weak self] in
            await self?.startMonitor()
        }
    }

    /// Temporarily speeds up responsiveness when a changing environment is predicted.
    public func prime() {
        Task {
            await HeadroomMonitor.shared.prime()
        }
    }

    private func startMonitor() async {
        await HeadroomMonitor.shared.multicaster.subscribe(id: subscriptionID) { [weak self] headroom in
            guard let self else { return }
            Task { 
                guard headroom != self.headroom else { return }
                self.headroom = headroom
            }
        }
    }

    isolated deinit {
        let id = subscriptionID
        Task {
            await HeadroomMonitor.shared.multicaster.unsubscribe(id: id)
        }
    }
}
