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

// MARK: Tone mapping

/// GPU twin of `ToneMap.apply(to:ceiling:)` in ToneMap.swift; keep the two in step. Compresses a color's brightest channel into `ceiling` (the
/// display's brightest component value) and scales every channel by the same factor, after pulling the color toward white by `burn` for light
/// brighter than the ceiling.
static float3 toneMapColor(float3 c, float knee, float peak, float burn, float ceiling) {
    c = max(c, 0.0);
    if (ceiling >= peak) return c;
    float kneeLevel = knee * ceiling;
    float m = max(c.r, max(c.g, c.b));
    if (m <= kneeLevel) return c;
    c = mix(c, float3(m), 1.0 - exp(-burn * max(m - ceiling, 0.0)));
    float t = saturate((m - kneeLevel) / (peak - kneeLevel));
    float k = (ceiling - kneeLevel) / (peak - ceiling);
    float mapped = kneeLevel + (ceiling - kneeLevel) * t * (1.0 + k) / (t + k);
    return c * (mapped / m);
}

/// Tone maps the layer's extended-range color. SwiftUI hands layers over premultiplied, so the color is unpremultiplied first and the curve acts
/// on the straight color, which keeps translucent edges from darkening.
[[ stitchable ]] half4 defaultToneMap(float2 position,
                                      SwiftUI::Layer layer,
                                      float knee,
                                      float peak,
                                      float burn,
                                      float ceiling) {
    half4 pixel = layer.sample(position);
    if (pixel.a <= 0.0h) return pixel;
    float3 straight = float3(pixel.rgb) / float(pixel.a);
    float3 mapped = toneMapColor(straight, knee, peak, burn, ceiling);
    return half4(half3(mapped * float(pixel.a)), pixel.a);
}
