//
//  PlatformImage.swift
//  SwiftEDR
//
//  Created by Jesse Hemingway on 9/20/26.
//

#if os(iOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import SwiftUI

public struct EDRImage: View {
    public struct Source: Equatable {
        public let data: Data
        public let info: ImageInfo

        public init(data: Data, info: ImageInfo? = nil ) {
            self.data = data
            self.info = info ?? data.edrImageInfo
        }
    }

    let source: Source

    @Environment(\.edrPalette) private var palette

#if os(iOS) || os(visionOS)
    @State private var processedImage: UIImage?
#elseif os(macOS)
    @State private var processedImage: CGImage?
#endif
    @State private var aspectRatio: CGSize = CGSize(width: 1, height: 1)

    public init(source: Source) {
        self.source = source
    }

    public var body: some View {
        VStack {
            if let processedImage {
#if os(iOS) || os(visionOS)
                Image(uiImage: processedImage)
                    .resizable()
#elseif os(macOS)
                Image(decorative: processedImage, scale: 1.0, orientation: .up)
                    .resizable()
#endif
            }
        }
        .task(id: source) {
            await processImageData()
        }
        .task(id: palette.profile) {
            await processImageData()
        }
    }
}

private extension EDRImage {
    private func processImageData() async {
        let wantsHDR = source.info.format != .sdr && palette.profile.mode == .hdr
        #if os(iOS)
        // Configure iOS HDR Engine
        var config = UIImageReader.Configuration()
        config.prefersHighDynamicRange = wantsHDR
        let reader = UIImageReader(configuration: config)

        if let uiImage = await reader.image(data: source.data) {
            self.processedImage = uiImage
        }
        #elseif os(macOS)
        // Configure macOS HDR Context Engine
        let options: [CIImageOption: Any] = [.expandToHDR: wantsHDR]
        guard let ciImage = CIImage(data: source.data, options: options) else { return }

        let context = CIContext()
        let colorSpace = ciImage.colorSpace ?? palette.profile.colorSpace

        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent, format: .RGBAh, colorSpace: colorSpace) {
            // Cache the aspect ratio sizes so the frame engine can bind it perfectly
            self.aspectRatio = CGSize(width: cgImage.width, height: cgImage.height)
            self.processedImage = cgImage
        }
        #endif
    }
}
