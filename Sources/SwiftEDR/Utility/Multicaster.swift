//
//  Multicaster.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/23/26.
//

import Foundation

/// A simple multicaster that executes callbacks on the main thread.
actor Multicaster<Value: Sendable> {
    private(set) var value: Value

    // Store simple, direct closures instead of complex stream continuations
    private var subscribers: [UUID: @MainActor (Value) -> Void] = [:]

    public init(_ initialValue: Value) {
        self.value = initialValue
    }

    /// Registers a consumer closure. It immediately fires the current value on the MainActor,
    /// and retains the closure to push future updates.
    func subscribe(
        id: UUID,
        onChange: @escaping @MainActor (Value) -> Void
    ) {
        self.subscribers[id] = onChange

        // 2. Immediately kick off the current value to the subscriber on the MainActor
        let initial = self.value
        Task { @MainActor in
            onChange(initial)
        }
    }

    /// Unregisters the consumer safely
    func unsubscribe(id: UUID) {
        subscribers.removeValue(forKey: id)
    }

    /// Broadcasts the new value to everyone simultaneously
    func updateValue(_ newValue: Value) {
        self.value = newValue

        // Loop over the active subscribers and push directly to the MainActor
        for onChange in subscribers.values {
            Task { @MainActor in
                onChange(newValue)
            }
        }
    }
}
