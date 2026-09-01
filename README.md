# SwiftEDR

A clean, convenient and performant mini-framework to bring EDR (extended dynamic range) and HDR (high dynamic range) display to any SwiftUI view.


## Features

SwiftEDR simplifies the somewhat intricate details related to using extended and high dynamic range bit depths and color spaces within SwiftUI. It also comes with a modest suite of common HDR accompaniments like Tone Mapping and Bloom.

#### Supported Modes 

* SDR (Standard Dynamic Range) – same color range as standard views, except you can apply a bloom effect. 
* EDR (Extended Dynamic Range) – extended color range with higher precision color math, bloom and tone mapping support.
* HDR (Extended Dynamic Range) – extended color range with higher precision color math, bloom and tone mapping support, and special display handling on compatible hardware.

### Example App
Take a peek at what kind of visual results you can expect! We encourage you to open the SwiftEDRExample app and experience the interactive demo. After all, a picture is worth a thousand words when it comes to visual gravy.

The demo UI controls are a good way to study the visual behavior of the various profile modes and effects. To access all controls, run on an iPad family device.


## Quick Start

Add SwiftEDR to your project using Swift Package Manager:
```swift
dependencies: [
    .package(url: "https://github.com/Jiropole/SwiftEDR.git", from: "1.0.0")
]
``` 

## Usage

There are two ways to leverage this package:
* Apply the `EDRModifier` view modifier to any existing SwiftUI view.
* Replace instances of SwiftUI's `Canvas` with `EDRCanvas`. 

### EDRModifier View Modifier

This view modifier allows you to apply EDR behaviors (defined by a Profile) to a specific view.

```swift
AnimatedHeroView()
    // Make it cinematic
    .modifier(EDRModifier(profile: .Defaults.hdrBloom))
```

### EDRCanvas View

This view is a more-or-less drop in replacement for SwiftUI Canvas. But why bother, you ask? Why not just use that sweet view modifier?

Well, the reason is simply to ensure the Canvas is properly configured for the current EDR mode, which can be fiddlesome to get right, and a good thing to DRY out. 

Note that this example passes the profile into to its renderer, so it can acquire colors in the correct color space, or modify its behavior based on the profile attributes.

```swift
TimelineView(.animation(minimumInterval: 1 / 30.0, paused: !isAnimating)) { timeline in
    let elapsed = timeline.date.timeIntervalSince(startDate)
    EDRCanvas(profile: profile,
              isOpaque: true,
              payload: elapsed) { context, size, elapsed in
        SuperAmazingRenderer(ctx: context,
                             size: size,
                             profile: profile,
                             time: elapsed)
        .render()
    }
}
```
 
 
## Key Concepts

### Profile Model 

The `Profile` model is of particular significance. Its role includes:
* Configuring the primary EDR mode along with related behaviors and effects.
* Vending colors and other values that are calibrated for the selected EDR mode. 

Use `Profile.Defaults` to quickly select a preset, or customize your own effects and display attributes. Note that little time has yet been spent on tuning Defaults. It may be common to tune the Bloom effect, in particular, to the specific content and desired aesthetics.

### Bloom Effect
Bloom is a cinematic effect that models bright areas of the scene as though they were light emissive. It is most useful for HDR, but SwiftEDR supports the effect in any EDR mode.

The current bloom implementation isolates luminous highlights and blurs them according to several parameters:
* Radius, which controls how far highlights may spread.
* Intensity, which controls how much the Bloom result is mixed back into the content.
* Threshold, which controls how bright a color needs to be to contribute to the effect.
* Knee, which controls how quickly or smoothly color values beyond the threshold contribute. 

### Tone Mapping
Tone mapping is a cinematic effect that allows color values to exceed the maximum SDR values during color processing. It is necessary and most useful for HDR, but SwiftEDR also supports the effect in EDR mode, to allow more flexible color design that will be properly handled by a high bit depth buffer. 

The current tone mapping implementation is a minor variant on the Reinhard filter. Improved versions may come.

 
 # License
This project is licensed under the MIT License - see the LICENSE file for details.
