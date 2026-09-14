//
//  HeadroomAsserter.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/13/26.
//


import SwiftUI

/// For HDR modes, assert that the app wants as much headroom as possible.
public struct HeadroomAsserter: ViewModifier {
    /// EDR profile configuration.
    public let profile: Profile
    /// EDR headroom information for use with tone mapping.
    public let headroom: Headroom

    public func body(content: Content) -> some View {
        content
            .background(alignment: .topLeading) {
                // Layer or color effects appear to break the chain of EDR metadata.
                // Therefore, we must remind the system we do want the headroom.
                if profile.mode == .hdr {
                    profile
                        .rgbColor([0, 0, 0, 0.01])
                        .headroom(headroom.potential)
                        .frame(width: 0.25, height: 0.25)
                }
            }
    }
}
