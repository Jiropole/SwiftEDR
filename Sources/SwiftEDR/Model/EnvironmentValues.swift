//
//  EnvironmentValues.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/11/26.
//

import SwiftUI

extension EnvironmentValues {
    /// The current SwiftEDR Profile.
    @Entry public var edrProfile: Profile = .Defaults.hdrBloom

    /// The current SwiftEDR Headroom.
    @Entry public var edrHeadroom: Headroom = .init()
}
