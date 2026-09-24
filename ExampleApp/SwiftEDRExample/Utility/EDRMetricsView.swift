//
//  EDRMetricsView.swift
//  SwiftEDRExample
//
//  Created by Jesse Hemingway on 9/24/26.
//


import SwiftUI
import PhotosUI
import SwiftEDR

struct EDRMetricsView: View {
    @Environment(\.edrPalette) private var palette

    var body: some View {
        Text(
"""
Headroom: \(palette.headroom.current, specifier: "%.2f") / \(palette.headroom.potential, specifier: "%.2f")
Adaptive threshold: \(palette.effectiveBloomThreshold, specifier: "%.2f")
""")
            .multilineTextAlignment(.trailing)
            .font(.caption)
            .padding(4)
            .background {
                Color.black.opacity(0.4)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .padding(4)
    }
}
