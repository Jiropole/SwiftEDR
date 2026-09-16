//
//  Headroom.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/9/26.
//

import Foundation

#if os(iOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public struct Headroom: BaseModel {
    public var current: CGFloat
    public var potential: CGFloat
    public var reference: CGFloat

    public init(current: CGFloat = 1, potential: CGFloat = 1, reference: CGFloat = 0) {
        self.current = current
        self.potential = potential
        self.reference = reference
    }

    /// Attempt to retrieve the raw physical headroom attributes.
    @MainActor public static func readHeadroom() -> Headroom? {
#if os(iOS)
        guard let screen = (NativeApplication.shared.connectedScenes
            .first as? UIWindowScene)?.screen else { return nil }
        return Headroom(current: screen.currentEDRHeadroom,
                        potential: screen.potentialEDRHeadroom)
#elseif os(macOS)
        guard let screen = NSApplication.shared.keyWindow?.screen else { return nil }
        return Headroom(current: screen.maximumExtendedDynamicRangeColorComponentValue,
                        potential: screen.maximumPotentialExtendedDynamicRangeColorComponentValue,
                        reference: screen.maximumReferenceExtendedDynamicRangeColorComponentValue)
#elseif os(visionOS)
        // Not aware of any way to get this value for VisionOS, or if it even applies.
        return Headroom()
#endif
    }

    /// Retrieve headroom attributes appropriate for the given profile.
    @MainActor public static func readHeadroomForProfile(_ profile: Profile) -> Headroom {
#if os(visionOS)
        var headroom = profile.mode == .hdr ? Headroom(current: 10, potential: 10, reference: 0) : .init()
#else
        var headroom = profile.mode == .hdr ? Headroom.readHeadroom() ?? .init() : .init()
#endif
        return Headroom(current: min(headroom.current, profile.maxHeadroom),
                        potential: min(headroom.current, profile.maxHeadroom),
                        reference: min(headroom.current, profile.maxHeadroom))
    }
}
