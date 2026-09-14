# SwiftEDR

A clean, convenient and performant mini-framework to bring EDR (extended dynamic range) and HDR (high dynamic range) display to any SwiftUI view.

## Platform Support
* iOS: Full support for iOS 26+.
* MacOS: Full support for MacOS 26+.
* VisionOS: Partial support for VisionOS 26+. Offers Bloom effect but HDR mode does not not presently result in increased brightness.

## Features

SwiftEDR simplifies the somewhat intricate details related to using extended and high dynamic range bit depths and color spaces within SwiftUI. It also offers a convenient Bloom effect.

#### Supported Modes 

* SDR – Standard Dynamic Range. SDR mode results in the same color range as standard views, but with the advantage that the Bloom effect can be applied.
* EDR – Extended Dynamic Range. EDR mode uses the standard color range, but with high precision color math when applied to Canvas views, with support for Bloom.  
* HDR – High Dynamic Range. HDR mode offers an extended color range, high precision color math for Canvas views, Bloom support, and the ability to display significantly brighter colors on compatible hardware.

Here are some examples of SDR, EDR and HDR. Note that screenshots cannot capture actual display results.

<img width="250" height="270" alt="swiftedr-sdr-mode" src="https://github.com/user-attachments/assets/45e22ca4-ae32-4ea8-8660-11e92041de86" />
<img width="250" height="270" alt="swiftedr-edr-mode" src="https://github.com/user-attachments/assets/fe98b027-3e02-44e3-ac02-0fb767d358ae" />
<img width="250" height="270" alt="swiftedr-hdr-mode" src="https://github.com/user-attachments/assets/8656e5ff-d3d9-4750-8757-769df3f158ca" />


### Example App
Take a peek at what kind of visual results you can expect! We encourage you to open the SwiftEDRExample app and experience the interactive demo. After all, a picture is worth a thousand words when it comes to visual gravy.

The demo UI controls are a good way to study the visual behavior of the various profile modes and effects. To access all controls, run on an iPad or Mac device.


## Quick Start

Add SwiftEDR to your project using Swift Package Manager:
```swift
dependencies: [
    .package(url: "https://github.com/Jiropole/SwiftEDR.git", from: "2.0.0")
]
``` 

## Usage

There are two ways to leverage this package:
* Apply the `EDRModifier` view modifier to any existing SwiftUI view.
* Replace instances of SwiftUI's `Canvas` with `EDRCanvas`. 

### EDRModifier View Modifier

This view modifier allows you to apply EDR behaviors, defined by a Profile, to a specific view.

```swift
AnimatedHeroView()
    // Make it cinematic
    .modifier(EDRModifier(profile: .Defaults.hdrBloom))
```

### EDRCanvas View

This view is a more-or-less drop in replacement for SwiftUI Canvas. But why bother, you ask? Why not just use that sweet modifier on a Canvas?

The main reason is simply to ensure the Canvas is properly configured for the current EDR mode. A secondary reason is to ensure the current Profile and Headroom are passed through to the drawing logic, so it can acquire colors in the correct color space, or modify its behavior based on the profile or headroom attributes.

```swift
TimelineView(.animation(minimumInterval: 1 / 30.0, paused: !isAnimating)) { timeline in
    EDRCanvas(isOpaque: true) { context, size, profile, headroom in
        SuperAmazingRenderer(ctx: context,
                             size: size,
                             profile: profile,
                             headroom: headroom,
                             elapsed: timeline.date.timeIntervalSince(startDate))
        .render()
    }
    .modifier(EDRModifier(profile: mySmoothBurstHDRProfile))    
}
```

Note that you apply the view modifier in just the same way as for any other view. EDRCanvas picks up the current Profile through the environment in order to configure the SwiftUI Canvas. If necessary, any view in the child tree can access the current profile or headroom using the likes of:

```swift
@Environment(\.edrProfile) private var profile
@Environment(\.edrHeadroom) private var headroom
``` 

 
## Key Concepts

### Profile Model 

The `Profile` model is of particular significance. Its role includes:
* Configuring the primary EDR mode along with related behaviors and effects.
* Vending colors and other values that are calibrated for the selected EDR mode. 

Use `Profile.Defaults` to quickly select a preset, or customize your own effects and display attributes. Note that little time has yet been spent on tuning Defaults. It may be common to tune the Bloom effect, in particular, to the specific content and desired aesthetics.

Profile is composed of the following attributes:
* `mode`, one of:
    * .sdr – Standard Dynamic Range (normal color range + bloom)
    * .edr - Extended Dynamic Range (normal color range + bloom)
    * .hdr – High Dynamic Range (extended color range + more)
* `bloom`, described below.
* `options', any of:
    * .bloomHighlightsOnly – show the bloom effect alone, hiding the content, for tuning.
    * .constrainedHDR – enable to constrain the maximum HDR brightness, for example to avoid overpowering adjacent UI or content elements. 


### Headroom
Headroom roughly indicates how bright a color can be beyond standard SDR brightness. So for SDR, this is always 1.0. This is also true for EDR, which does not request higher dynamic range. 

For HDR, this value can range very high. For an older phone, the limit might be 8.0, or roughly 8x brighter than the SDR equivalent. On newer devices this can be 16.0 or higher.

Increased headroom doesn't change the brightness of a view on its own. Apps must take advantage of the headroom by choosing or blending colors that exceed 1.0, up to or past the headroom. Color values near or over the headroom are tone mapped back into the display color space. When selecting colors, use the current Profile to get colors in the appropriate color space. The profile is available through the environment or within an ERDCanvas draw function, as described above.


### Bloom Effect
Bloom is a cinematic effect that models bright areas of the scene as though they were light emissive. It is most useful for HDR, but SwiftEDR supports the effect in any EDR mode.

The current bloom implementation isolates luminous highlights and blurs them according to several parameters:
* Radius, which controls how far highlights may spread.
* Intensity, which controls how much the Bloom result is mixed back into the content.
* Threshold, which controls how bright a color needs to be to contribute to the effect.
* Knee, which controls how quickly or smoothly color values beyond the threshold contribute. 

Note that as headroom increases, it may be necessary to adjust the bloom threshold to avoid bloom blowout – a nasty business. Perhaps this can eventually be automated, but couldn't find a naive approach that didn't take away aesthetic choice. 


## Color Design
Here is a final thought with regards to color design and HDR mode.

Color design for SDR and EDR are very similar, as the output color ranges and gamma are identical. But colors are interpreted somewhat differently when displayed in HDR mode, which may affect color design decisions.

HDR color design can take adantage of colors whose component values exceed the maximum SDR display brightness or darkness, taking into account the current headroom, to achieve deeper tonal contrast. 

Some rather crude examples to illustrate:
* SDR red in RGB: (1, 0, 0). Or, mega-red in HDR: (10, 0, 0)
* SDR white in HSV: (0, 0, 1). Or mega-white in HDR: (10, 0, 2) 

This visual gravy comes with a price: as color values grow "hotter" there is increased tonal non-linearity. There is no practical upper limit on color component values, because tone mapping squeezes this range back into expressible pixel values. This non-linearity may be further accentuated when significant Bloom is present.

Therefore, while this package can be used to quickly add a cinematic effect to tastefully chosen elements of any SwiftUI application, best results may be achieved using content colors designed around the advantages and challenges of HDR.

 
 # License
This project is licensed under the MIT License - see the LICENSE file for details.
