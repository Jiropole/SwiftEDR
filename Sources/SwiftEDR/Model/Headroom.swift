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
    
#if os(iOS) || os(visionOS)
    public init(screen: NativeScreen) {
        self.current = screen.currentEDRHeadroom
        self.potential = screen.potentialEDRHeadroom
        self.reference = 0
    }
#elseif os(macOS)
    public init(screen: NativeScreen) {
        self.current = screen.maximumExtendedDynamicRangeColorComponentValue
        self.potential = screen.maximumPotentialExtendedDynamicRangeColorComponentValue
        self.reference = screen.maximumReferenceExtendedDynamicRangeColorComponentValue
    }
#endif
}
