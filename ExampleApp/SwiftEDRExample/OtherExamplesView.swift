//
//  OtherExamplesView.swift
//  SwiftEDRExample
//
//  Created by Jesse Hemingway on 9/13/26.
//

import SwiftUI
import PhotosUI
import SwiftEDR

struct OtherExamplesView: View {
    let elapsed: CGFloat
    @Binding var selectedSource: EDRImage.Source?

    @Environment(\.edrPalette) private var palette

    @State private var isShowingImage: Bool = true
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottom) {
                Group {
                    if isShowingImage {
                        imageView
                    } else {
                        customView
                    }
                }
                HStack {
                    imageMetricsView
                    Spacer()
                    edrMetricsView
                }
                .foregroundStyle(palette.rgbColor([1, 1, 1, 1], boost: palette.headroom.current * 0.25))
                .font(.caption)
            }

            HStack {
                Picker("Example", selection: $isShowingImage) {
                    Text("Custom").tag(false)
                    Text("Image").tag(true)
                }
                .pickerStyle(.segmented)

                PhotosPicker(selection: $selectedItem, matching: .any(of: [.images, .not(.screenshots), .not(.videos)])) {
                    Label("Select", systemImage: "photo.stack")
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .onChange(of: selectedItem) { _, newItem in
            isShowingImage = true
            _ = Task {
                await processPhotosSelection(newItem)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private extension OtherExamplesView {
    func processPhotosSelection(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self) else { return }
        self.selectedSource = .init(data: data)
    }

    var imageView: some View {
        VStack(alignment: .trailing) {
            if let selectedSource {
                EDRImage(source: selectedSource)
            } else {
                Image(systemName: "photo.fill")
                    .resizable()
                    .foregroundStyle(Color.white.opacity(0.15))
            }
        }
        .scaledToFit()
    }

    var customView: some View {
        func subImage(offset: CGFloat) -> some View {
            let stepElapsed = elapsed + offset
            return Circle()
                .mask {
                    Image(systemName: "progress.indicator", variableValue: fmod(stepElapsed / 4, 1))
                        .resizable().scaledToFit()
                }
                .fontWeight(.bold)
                .foregroundStyle(colorAtElapsed(stepElapsed))
                .rotationEffect(.radians(.pi / 8 * offset + .pi * offset))
        }
        return ZStack {
            Group {
                subImage(offset: 0)
                subImage(offset: 0.25)
                subImage(offset: 0.5)
                subImage(offset: 0.75)
            }
            .blendMode(.plusLighter)
        }
    }

    var edrMetricsView: some View {
        Text("Headroom: \(palette.headroom.current, specifier: "%.2f") / \(palette.headroom.potential, specifier: "%.2f")\nAdaptive threshold: \(palette.effectiveBloomThreshold, specifier: "%.2f")")
            .multilineTextAlignment(.trailing)
            .padding(4)
            .background {
                Color.black.opacity(0.4)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .padding(4)
    }

    var imageMetricsView: some View {
        Group {
            if isShowingImage, let selectedSource {
                Text("\(selectedSource.info.format.rawValue)\nHeadroom: \(selectedSource.info.headroom, specifier: "%.2f")")
                    .multilineTextAlignment(.leading)
                    .padding(4)
                    .background {
                        Color.black.opacity(0.4)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .padding(4)
            }
        }
    }

    func colorAtElapsed(_ elapsed: CGFloat) -> Color {
        return palette.hsvColor([
            fmod(elapsed / 8, 1), // hue
            0.8 + 0.2 * sin(elapsed * 2 * .pi / 3), // saturation
            (0.6 + 0.4 * sin(elapsed * 2 * .pi / 5)), // value/brightness
            1.0 // opacity
        ], boost: palette.headroom.current)
    }
}
