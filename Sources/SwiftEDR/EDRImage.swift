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

/// Use EDRImage as cross platform alternative to Swift Image, supporting extended EDR behaviors and color handling.
/// It is of primary use when it is convenient to provide the raw image data, or a cgImage created with headroom.
public struct EDRImage: View {

    /// Source used for EDR Image.
    public enum Source: Equatable {
        /// Source is data, for example from a url or the photo library.
        case data(_ data: Data)
        /// Source is an image, which may have limited metadata depending on how it was created.
        case image(_ cgImage: CGImage)
    }

    private let source: Source
    private let metadata: ImageMetadata

    @Environment(\.edrPalette) private var palette
    @State private var aspectRatio: CGSize = CGSize(width: 1, height: 1)

#if os(iOS) || os(visionOS)
    @State private var processedImage: UIImage?
#elseif os(macOS)
    @State private var processedImage: CGImage?
#endif

    public init(source: Source, metadata: ImageMetadata? = nil) {
        self.source = source
        self.metadata = metadata ?? source.embeddedMetadata
        if case .image(let cgImage) = source {
            // Populate the image immediately for image source
#if os(iOS) || os(visionOS)
            self.processedImage = UIImage(cgImage: cgImage)
#elseif os(macOS)
            self.processedImage = cgImage
#endif
        }
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
        guard case .data(let imageData) = source else { return }

        let wantsHDR = metadata.format != .sdr && palette.profile.mode == .hdr
        #if os(iOS)
        // Configure iOS HDR Engine
        var config = UIImageReader.Configuration()
        config.prefersHighDynamicRange = wantsHDR
        let reader = UIImageReader(configuration: config)

        if let uiImage = await reader.image(data: imageData) {
            self.processedImage = uiImage
        }
        #elseif os(macOS)
        // Configure macOS HDR Context Engine
        let options: [CIImageOption: Any] = [.expandToHDR: wantsHDR]
        guard let ciImage = CIImage(data: imageData, options: options) else { return }

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

public extension EDRImage.Source {
    var embeddedMetadata: ImageMetadata {
        switch self {
        case .data(let data):
            return data.edrImageMetadata
        case .image(let cgImage):
            return cgImage.edrImageMetadata
        }
    }
}
