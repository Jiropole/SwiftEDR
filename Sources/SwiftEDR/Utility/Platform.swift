//
//  Platform.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/9/26.
//

import Foundation

#if os(iOS) || os(visionOS)
import UIKit
public typealias NativeApplication = UIApplication
public typealias NativeColor = UIColor
public typealias NativeImage = UIImage
#elseif os(macOS)
import AppKit
public typealias NativeApplication = NSApplication
public typealias NativeColor = NSColor
public typealias NativeImage = NSImage
#endif
