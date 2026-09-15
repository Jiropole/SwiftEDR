//
//  EnvironmentValues.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/11/26.
//

import SwiftUI

extension EnvironmentValues {
    
    /// Vends EDR state and colors.
    @Entry public var edrPalette: Palette = .init(profile: .Defaults.hdrBloom,
                                                  headroom: .init())
}
