//
//  HeadroomAsserter.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/13/26.
//

import SwiftUI

/// For HDR modes, assert that the app wants as much headroom as possible. Works best with app also using .headroom() on its colors.
public struct HeadroomAsserter: ViewModifier {
    
    @Environment(\.edrPalette) private var palette

    public func body(content: Content) -> some View {
        content
            .background(alignment: .topLeading) {
                // Layer or color effects appear to break the chain of EDR metadata.
                // Therefore, we must remind the system we do want the headroom.
                if palette.profile.mode == .hdr {
                    palette
                        .rgbColor([0, 0, 0, 0.01])
                        .frame(width: 0.25, height: 0.25)
                }
            }
    }
}
