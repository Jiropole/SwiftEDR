//
//  Shaders.metal
//  CycloStudio
//
//  Created by Jesse Hemingway on 8/30/26.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

[[ stitchable ]] half4 extractOverbrights(float2 position,
                                          SwiftUI::Layer layer,
                                          float threshold,
                                          float kneeWidth,
                                          float premultiplier) {
    // Grab the sharp base canvas pixel
    half4 coreColor = layer.sample(position) * premultiplier;

    // Determine perceived luminance using standard P3/sRGB weights
    half luminance = dot(coreColor.rgb, half3(0.2126h, 0.7152h, 0.0722h));

    // Smoothstep soft knee into full bloom weight
    float lowBound = threshold - kneeWidth;
    float highBound = threshold + kneeWidth;
    half bloomWeight = half(smoothstep(lowBound, highBound, float(luminance)));

    // Final value is the original color scaled by bloom weight.
    return coreColor.rgba * bloomWeight;
}

[[ stitchable ]] half4 defaultToneMap(float2 position,
                                        SwiftUI::Layer layer,
                                        float headroom) {
    half4 color = layer.sample(position);

    // Extract color values above SDR 1.0
    half3 toneMappableRGB = max(half3(0.0h), color.rgb - half3(1.0h));
    // Calculate reinhard inverse scalar for values over 1.0
    half3 inverseReinhardRGB = half3(1.0) / (toneMappableRGB + half3(1.0h));

    // Define EDR headroom as that above SDR 1.0
    half edrHeadroom = half(headroom) - half(1.0h);
    // Calculate tone mapped values scaled to the EDR headroom
    half3 toneMappedRGB = toneMappableRGB * inverseReinhardRGB * edrHeadroom;
    // Final value is SDR value + tone mapped EDR value
    half3 finalRGB = min(half3(1.0), color.rgb) + toneMappedRGB;

    return half4(finalRGB, color.a);
}
