//
//  Shaders.metal
//  CycloStudio
//
//  Created by Jesse Hemingway on 8/30/26.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

//
//  Shaders.metal
//  CycloStudio
//
//  Created by Jesse Hemingway on 8/30/26.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

//[[ stitchable ]] half4 hdrBloom(
//    float2 position,
//    SwiftUI::Layer layer,
//    float radius,
//    float threshold,
//    float intensity // New parameter to directly control the glow strength
//) {
//    // 1. Grab the sharp base canvas pixel
//    half4 coreColor = layer.sample(position);
//
//    // 2. Perform a multi-ring texture sampling pass
//    half3 blurredColors = half3(0.0h);
//
//    // Core sampling offsets mapping an inner and outer ring footprint
//    float2 offsets[8] = {
//        float2(-0.707f, -0.707f), float2(0.707f, -0.707f),
//        float2(-0.707f,  0.707f), float2(0.707f,  0.707f),
//        float2(-1.5f, 0.0f),      float2(1.5f, 0.0f),
//        float2(0.0f, -1.5f),      float2(0.0f, 1.5f)
//    };
//
//    for (int i = 0; i < 8; i++) {
//        float2 sampleCoord = position + (offsets[i] * radius);
//        half3 neighbor = layer.sample(sampleCoord).rgb;
//
//        // BRIGHT PASS: Only accumulate neighbor colors if they exceed the threshold
//        half neighborLuminance = dot(neighbor, half3(0.2126h, 0.7152h, 0.0722h));
//        if (neighborLuminance > threshold) {
//            // Isolate the over-bright aspect of the neighbor
//            blurredColors += (neighbor - half3(threshold)) * 0.125h;
//        }
//    }
//
//    // 3. Inject the accumulated bloom layer back over the core image
//    // Multiplying by the 'intensity' parameter forces a measurable color bleed
//    half3 compositeImage = coreColor.rgb + (blurredColors * intensity);
//
//    // 4. BALANCED TONE MAPPING (Keeps your native P3 values crisp, rolls off extremes)
//    half maxVal = max(compositeImage.r, max(compositeImage.g, compositeImage.b));
//    half3 finalRGB;
//
//    if (maxVal > 1.0h) {
//        // Soft exponential roll-off that preserves room for the bloom glow to be seen
//        finalRGB = compositeImage / (1.0h + (compositeImage * 0.15h));
//    } else {
//        // Keeps native dynamic range completely untouched for deep blacks
//        finalRGB = compositeImage;
//    }
//
//    return half4(finalRGB, coreColor.a);
//}

[[ stitchable ]] half4 extractOverbrights(
                                          float2 position,
                                          SwiftUI::Layer layer,
                                          float threshold,
                                          float kneeWidth,
                                          float premultiplier
                                          ) {
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
//    half3 finalRGB = coreColor.rgb * bloomWeight;
//    return half4(finalRGB, coreColor.a);
}

[[ stitchable ]] half4 cinematicToneMap(
                                        float2 position,
                                        SwiftUI::Layer layer
                                        ) {
    half4 color = layer.sample(position);
    half3 finalRGB;

    // Find the peak color component
    half maxVal = max(color.r, max(color.g, color.b));

    if (maxVal > 1.0h) {
        // When values exceed unity, apply Filmic Aces/Reinhard Hybrid Roll-off
        // Gracefully bends extreme HDR values past 1.0 down without crushing contrast
        half3 inverseMax = half3(1.0h) / (color.rgb + half3(1.0h));
        finalRGB = color.rgb * inverseMax * maxVal;

        // Give a slight cinematic lift to over-bright peaks so they look emissive
        finalRGB += (color.rgb - half3(1.0h)) * 0.1h;
    } else {
        // Standard color range is lefgt untouched
        finalRGB = color.rgb;
    }

    return half4(color.rgb, color.a);
}
