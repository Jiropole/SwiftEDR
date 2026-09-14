//
//  EnvironmentValues.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/11/26.
//

import SwiftUI

extension EnvironmentValues {
    
    /// Vends EDR state and colors.
    @Entry public var palette: Palette = .init(profile: .Defaults.hdrBloom,
                                               headroom: .init())
}
