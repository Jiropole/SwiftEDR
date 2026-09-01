//
//  SwiftEDRDiagnostics.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 8/31/26.
//


import SwiftUI

public struct Diagnostics: OptionSet, BaseModel {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let bloomHighlightsOnly = Self(rawValue: 1 << 0)
    public static let futureDiagnostic = Self(rawValue: 1 << 1)

    public var isBloomHighlightsOnly: Bool {
        get { contains(.bloomHighlightsOnly) }
        set { if newValue { insert(.bloomHighlightsOnly) } else { remove(.bloomHighlightsOnly) } }
    }
}
