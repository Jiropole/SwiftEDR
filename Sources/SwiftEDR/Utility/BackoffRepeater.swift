//
//  BackoffRepeater.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/13/26.
//

import Foundation

/// Manages execution of a function with an adaptive callback frequency.
public actor BackoffRepeater {
    /// Callback returns true if the timer interval should continue or speed up, or false if it should slow down.
    public typealias FunctionBody = @Sendable () async -> Bool

    public let delayRange: ClosedRange<TimeInterval>
    public let tolerance: TimeInterval

    private var debounceTask: Task<Void, Never>?
    private var nextDelay: TimeInterval

    public init(delayRange: ClosedRange<TimeInterval>, tolerance: TimeInterval? = nil) {
        self.delayRange = delayRange
        self.nextDelay = delayRange.lowerBound
        self.tolerance = tolerance ?? delayRange.lowerBound * 0.5
    }

    public func execute(speedUp: Bool = false, _ body: @escaping FunctionBody) {
        if speedUp {
            nextDelay = delayRange.lowerBound
        }
        scheduleTimeoutWithBody(body)
    }

    isolated deinit {
        debounceTask?.cancel()
    }
}

private extension BackoffRepeater {
    func scheduleTimeoutWithBody(_ body: @escaping FunctionBody) {
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(nextDelay),
                                  tolerance: .seconds(tolerance))
            guard !Task.isCancelled else { return }
            await timoutFiredWithBody(body)
        }
    }

    func timoutFiredWithBody(_ body: @escaping FunctionBody) async {
        let faster = await body()
        if faster {
            nextDelay = delayRange.lowerBound
        } else {
            nextDelay = min(delayRange.upperBound, nextDelay * 2)
        }
        scheduleTimeoutWithBody(body)
    }
}
