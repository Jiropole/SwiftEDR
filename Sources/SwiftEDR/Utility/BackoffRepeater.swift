//
//  BackoffRepeater.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/13/26.
//


import SwiftUI

/// Manages execution of a function with an adaptive callback frequency.
public class BackoffRepeater {
    /// Callback returns true if the timer interval should back off (slow down), else false if it should continue or speed up.
    public typealias FunctionBody = () -> Bool

    public let delayRange: ClosedRange<TimeInterval>
    public let tolerance: TimeInterval

    private var debounceTimer: Timer?
    private var nextDelay: TimeInterval

    public init(delayRange: ClosedRange<TimeInterval>, tolerance: TimeInterval? = nil) {
        self.delayRange = delayRange
        self.nextDelay = delayRange.lowerBound
        self.tolerance = tolerance ?? delayRange.lowerBound * 0.5
    }

    public func execute(_ body: @escaping FunctionBody) {
        scheduleTimerWithBody(body)
    }

    deinit {
        debounceTimer?.invalidate()
    }
}

private extension BackoffRepeater {
    func scheduleTimerWithBody(_ body: @escaping FunctionBody) {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: nextDelay, repeats: false, block: { [weak self] _ in
            self?.timerFiredWithBody(body)
        })
        debounceTimer?.tolerance = tolerance
    }

    func timerFiredWithBody(_ body: @escaping FunctionBody) {
        let shouldBackoff = body()
        if shouldBackoff {
            nextDelay = min(delayRange.upperBound, nextDelay * 2)
        } else {
            nextDelay = max(delayRange.lowerBound, nextDelay / 2)
        }
        scheduleTimerWithBody(body)
    }
}
