//
//  NumberFormatter+App.swift
//  EDRTestLab
//
//  Created by Jesse Hemingway on 8/28/26.
//

import Foundation

extension NumberFormatter {
    static let fractional3: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 3
        return formatter
    }()
}
