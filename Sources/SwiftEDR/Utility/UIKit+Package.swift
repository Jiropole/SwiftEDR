//
//  UIKit+Package.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/9/26.
//

import Foundation

#if os(iOS) || os(visionOS)
import UIKit
public typealias NativeApplication = UIApplication
public typealias NativeScreen = UIScreen
public typealias NativeColor = UIColor
//public typealias NativeViewRepresentable = UIViewRepresentable
#elseif os(macOS)
import AppKit
public typealias NativeApplication = NSApplication
public typealias NativeScreen = NSScreen
public typealias NativeColor = NSColor
//public typealias NativeViewRepresentable = NSViewRepresentable
#endif


extension NativeScreen {
    /// Cross-platform method to get the present display screen.
    static var displayScreen: NativeScreen? {
#if os(iOS) || os(visionOS)
        (NativeApplication.shared.connectedScenes.first as? UIWindowScene)?.screen
#elseif os(macOS)
        NativeApplication.shared.keyWindow?.screen
#endif
    }

    /// Retrieve headroom info for the current (iOS/VisionOS) or main (MacOS) screen.
    static var headroom: Headroom? {
        guard let screen = NativeScreen.displayScreen else { return nil }
        return Headroom(screen: screen)
    }
}
