//
//  Shaders.metal
//  CycloStudio
//
//  Created by Jesse Hemingway on 8/30/26.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

[[ stitchable ]] half4 extractLuminanceOverbrights(float2 position,
                                                   SwiftUI::Layer layer,
                                                   float threshold,
                                                   float kneeWidth,
                                                   float premultiplier) {
    // Grab the sharp base canvas pixel
    half4 color = layer.sample(position);
    half3 rgb = color.rgb * premultiplier;

    // Use strongest component to determine emissiveness.
    half emissiveness = max(rgb.r, max(rgb.g, rgb.b));

    // Smoothstep soft knee into full bloom weight
    float lowBound = threshold - kneeWidth;
    float highBound = threshold + kneeWidth;
    half bloomWeight = half(smoothstep(lowBound, highBound, float(emissiveness)));

    // Final value is the premultiplied color scaled by bloom weight.
    return half4(rgb * bloomWeight, color.a);
}

[[ stitchable ]] half4 extractComponentOverbrights(float2 position,
                                                   SwiftUI::Layer layer,
                                                   float threshold,
                                                   float kneeWidth,
                                                   float premultiplier) {
    // Grab the sharp base canvas pixel
    half4 color = layer.sample(position);
    half3 rgb = color.rgb * premultiplier;

    // Smoothstep soft knee into full bloom weight
    float lowBound = threshold - kneeWidth;
    float highBound = threshold + kneeWidth;
    half3 bloomWeight = smoothstep(lowBound, highBound, rgb);

    // Final value is the original color scaled by bloom weight.
    return half4(rgb * bloomWeight, color.a);
}
