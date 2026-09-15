# SwiftEDR
A clean, convenient and performant mini-framework to bring EDR (extended dynamic range) and HDR (high dynamic range) display to any SwiftUI view.

SwiftEDR is entirely hand coded in SwiftUI and MSL. AI fulfilled a limited role around topic research and comprehension.

## Platform Support
* iOS: Full support for iOS 26+, but high dynamic range not available on simulators.
* MacOS: Full support for MacOS 26+, but high dynamic range not available on simulators.
* VisionOS: Full-ish support for VisionOS 26+. I only say "full-ish" because there may be VisionOS amenities I'm not aware of.

## Features
SwiftEDR simplifies the somewhat intricate details related to using extended and high dynamic range bit depths and color spaces within SwiftUI. It also offers a convenient Bloom effect.

### Supported Modes 
* SDR – Standard Dynamic Range. SDR mode results in the same color range as standard views, but with the advantage that the Bloom effect can be applied.
* EDR – Extended Dynamic Range. EDR mode uses the standard color range, but with high precision color math when applied to Canvas views, and support for the Bloom effect.  
* HDR – High Dynamic Range. HDR mode offers an extended color range, high precision color math for Canvas views, Bloom support, and the ability to display significantly brighter colors on compatible hardware.

You may be thinking "show me the HDR already" – which is admittedly the most interesting thing about this package. But HDR is most impressive when you have something to compare it to. Plus the other modes may be useful to vary display parameters according to user focus. It is also a nice practice to revert to non HDR modes when energy conservation is important or when not justified by present content or available headroom.

Here are some examples of SDR, EDR and HDR, noting that images can only simulate actual display results. Screenshotting HDR can easily look like blown out crap.

<p align="center">
<img width="250" height="270" alt="swiftedr-sdr-mode" src="https://github.com/user-attachments/assets/45e22ca4-ae32-4ea8-8660-11e92041de86" />
<img width="250" height="270" alt="swiftedr-edr-mode" src="https://github.com/user-attachments/assets/fe98b027-3e02-44e3-ac02-0fb767d358ae" />
<img width="250" height="270" alt="swiftedr-hdr-mode" src="https://github.com/user-attachments/assets/8656e5ff-d3d9-4750-8757-769df3f158ca" />
</p>

#### What It Isn't
SwiftEDR doesn't magically make any view brighter and more vivid – that still takes careful design decisions. It also isn't a color production studio in a package. It merely organizes the sprawling details around bit depths and dynamic ranges into a concise API surface, so you can focus on tuning tuning EDR for your own use cases, without leaving the speed and comfort of SwiftUI. 

### Example App
Take a peek at what kind of visual results you can expect by opening the SwiftEDRExample app and running the interactive demo on Mac or a physical device. A picture is worth a thousand words when it comes to visual gravy.

The demo UI controls are a good way to study the visual behavior of the various profile modes and effects. To access all controls, run on an iPad or Mac device.

There is a bonus mode "SDR-NL", which displays like a typical SwiftUI canvas, using the nonlinear P3 color space. This may be perfectly adequate for many purposes, but higher bit depth math goes hand in hand with linear color space, which is why SwiftEDR SDR mode will be brighter but lower contrast out of the box. This can be countered with careful use of extended color ranges. (In the future, this package could also be made more flexible for customization or custom shaders in the pipeline.)

You are unlikely to see any difference between (linear) SDR and EDR modes, but rest assured the color math is much higher precision for the latter, and can be useful for detailed blending or when used with shaders. You should definitely see a difference in HDR mode, as the demo app will request maximum headroom, and the drawing algorithm will use colors that are able to display far hotter than the SDR maximum.

The main display area is covered with an example of an `EDRCanvas`, i.e. a SwiftEDR-powered Canvas view. For the hovering icons, above it, a legend:
* "ladybug" – Displays the bloom effect by itself, in order to more easily tune it.
* "dot-wheel" - Enables component bloom thresholding, as opposed to luminance thresholding.
* "constrain" - Enables system-throttled HDR headroom; for example, to avoid overpowering adjacent content or to save energy.
* "photo" - Displays an example of applying `EDRModifier` to arbitrary, non-Canvas views.
* "back-circle" – Reset all parameters.
* "pause/play" – Play or pause animation. 

## Quick Start
Add SwiftEDR to your project using Swift Package Manager:
```swift
dependencies: [
    .package(url: "https://github.com/Jiropole/SwiftEDR.git", from: "2.0.0")
]
``` 

## Usage
There are three steps to properly leverage this package:
* Apply the `EDRModifier` view modifier to any standard or custom SwiftUI view, including `EDRCanvas`.
* Replace instances of SwiftUI's `Canvas` with `EDRCanvas`. 
* Acquire all drawing colors from the environment `edrPalette`, or the `palette` passed to the EDRCanvas `onDraw` function.

### EDRModifier View Modifier
This view modifier allows you to apply EDR behaviors, defined by a Profile, to a specific view.

```swift
AnimatedHeroView()
    // Make it cinematic
    .modifier(EDRModifier(profile: .Defaults.hdrBloom))
```

Unfortunately, most SwiftUI views will not deal gracefully with HDR colors. However, it does work for shapes, so one workaround is to display a shape using HDR color, masked to the target view. Improving the powers of this modifier is in the queue.

### EDRCanvas View
The original intent behind this package! This view is a drop-in replacement for SwiftUI Canvas that supports generative content that is adaptive to wider dynamic ranges. But why bother, you ask? Why not just use that sweet modifier on a Canvas?

The main reason is simply to ensure the Canvas is properly configured for the current EDR mode. A secondary reason is to ensure the current Palette is passed through to the drawing logic, so it can acquire colors in the correct color space, or modify its behavior based on the profile or headroom attributes.

```swift
TimelineView(.animation(minimumInterval: 1 / 30.0, paused: !isAnimating)) { timeline in
    EDRCanvas(isOpaque: true) { context, size, palette in
        SuperAmazingRenderer(ctx: context,
                             size: size,
                             palette: palette,
                             elapsed: timeline.date.timeIntervalSince(startDate))
        .render()
    }
    .modifier(EDRModifier(profile: mySmoothBurstHDRProfile))    
}
```

Note that you apply the EDRModifier in just the same way as for any other view. 
 
## Core Concepts
### Profile Model 
The `Profile` model configures the primary EDR mode along with related behaviors and effects. Use `Profile.Defaults` to quickly select a preset, or customize your own effects and display attributes. It may be desirable to tune the Bloom effect, in particular, to your specific content and desired aesthetics.

Profile is composed of the following attributes:
* `mode`, one of:
    * .sdrNonLinear – Standard Dynamic Range with nonlinear P3 color value in the range [0, 1] + bloom. This will look the same as a basic, unadorned SwiftUI Canvas.
    * .sdr – Standard Dynamic Range with linear P3 color values in the range [0, 1]. This will look brighter than an unadorned SwiftUI Canvas.
    * .edr - Extended Dynamic Range with linear P3 color values in the range [0, 1]. This will normally look just like `.sdr`, but computed at higher bit depth.
    * .hdr – High Dynamic Range with with linear P3 color values in the range [0, ∞). If display is compatible and headroom is available, colors may display many times brighter than SDR.
* `bloom`, described below.
* `maxHeadroom` – Constrains the maximum requested headroom in HDR mode. Even values as low as 2-5 can be striking. Use this for more specific control than offered by the .constrainedHDR option.
* `options`, any of:
    - .bloomHighlightsOnly – show the bloom effect alone, hiding the content, for tuning.
    * .constrainedHDR – enable to enable system-throttled HDR brightness, for example to avoid overpowering adjacent content or to reduce energy usage. 

### Palette Model
The `Palette` model has two roles:
* Wraps all EDR state into a single object that can be easily passed via the environment and queried to implement adaptive behaviors.  
* Serves as the authoritative Color vendor, ensuring colors are properly suited to the current color space and dynamic range.

Here is an example of using the palette to generate colors calibrated for the mode and dynamic range.

```swift
@Environment(\.edrPalette) private var palette
    
var sdrBlue: Color {
    // Safe for use with any profile!
    palette.rgbColor([0.1, 0.2, 1.0, 1.0])    
}

var hdrBlue: Color {
    // Safe for use with any profile, and takes advantage of HDR headroom!
    let hdrPower = palette.headroom.current * 0.67
    return palette.rgbColor([0.1 * hdrPower, 0.2 * hdrPower, 1.0 * hdrPower, 1])    
}
```


### Headroom
Headroom indicates how bright a color can be beyond standard SDR brightness. For SDR, this is always 1.0. This is also true for EDR, which does not request higher dynamic range. 

For HDR, this value can range far past 1.0. For an older phone, the limit might be 8.0, or roughly 8x brighter than the SDR equivalent. On newer devices this can be 16.0 or higher. 

This can result in startlingly bright colors popping out of an otherwise-SDR display! For this reason, consider reining in this power. On the aesthetic side, HDR was really meant to let smaller areas of the screen pop, or for transient effects like lightning – not for firehosing the viewer with photons! 

Beyond aesthetic choices, there are also two important ways to globally limit how much headroom is requested, and they can be used together:
* For strict control, try setting an arbitrary number lower than the screen potential for Profile attribute `maxHeadroom`. Even 3X is noticeably brighter than surrounding UI! 
* Alternately or combined, to enable system-determined headroom throttling, include `.constrainedHDR` with Profile `options`.

Increased headroom doesn't change the brightness of a view on its own. Apps must take advantage of the headroom by choosing or blending colors that exceed 1.0, up to, or past the headroom. Color values near or over the headroom are clamped or tone mapped back into the display color space. When selecting colors, use the current Palette to get colors in the appropriate color space and dynamic range.


### Bloom Effect
Bloom is a cinematic effect that models bright areas of the scene as though they were light emissive. It is most useful for HDR, but SwiftEDR supports the effect in any EDR mode.

The current bloom implementation isolates luminous highlights in order to blur and blend them according to several parameters:
* Radius, which controls how far highlights may spread.
* Intensity, which controls how much the Bloom result is mixed back into the content.
* Threshold, which controls how bright a color needs to be to contribute to the effect.
* Mode, selecting between luminosity or component based thresholding. The latter results in a more saturated effect, allowing e.g. blues to glow as much as greens. 
* Knee, which controls how quickly or smoothly color values beyond the threshold contribute. 
* Adaptivity, which controls to what degree the bloom threshold increases with the current headroom.

These are best dialed to desired aesthetics, as there is no one size that fits all. For example in HDR, colors values will naturally blow past a fixed threshold; or `.component` Bloom mode tends to significantly increase Bloom contribution. Thus, parameters will typically need to be tuned around such decisions. On the upside, one may experiment with these parameters using the Example App described above, or use the same flags the example app uses to tune EDR effects within any client application.

Note that as headroom increases, it may be necessary to adjust the bloom threshold or knee to avoid bloom blowout – a nasty business. Adaptivity helps automate this adjustment, but the app could also opt to set adaptivity to 0.0 and manually tune the threshold.


## Color Design Note
Color design for SDR and EDR are very similar, as the output color ranges are identical. But colors are interpreted somewhat differently when displayed in HDR mode, which may affect color design decisions.

HDR color design can take adantage of colors whose component values exceed the maximum SDR display brightness or darkness, taking into account the current headroom, to achieve deeper tonal contrast. 

Let's say the current headroom is 12. Some rather crude examples to review:
* SDR red in RGB: (1, 0, 0). Or, pop-out red in HDR: (10, 0, 0)
* SDR white in HSV: (0, 0, 1). Or pop-out white in HDR: (0, 0, 10) 

Note that it is NOT necessary to indicate the desired headroom when colors are acquired through the Palette. However, if you create colors yourself, you will want to specify the desired headroom in order to drive demand on the HDR subsystem. For example:

```swift
@Environment(\.palette) private var palette
    
var popoutRed: Color {
    myVeryRedCustomColor.headroom(palette.headroom.potential)
}
```

Also of note, as color values grow "hotter", there is the capacity for increased tonal non-linearity. There is no practical upper limit on color component values, because clamping or tone mapping squeezes this range back into expressible pixel values. This non-linearity may be further accentuated when significant Bloom is present. 

It is best to take the current headroom into account when choosing colors, as shown above, but also when considering how colors may become hotter with certain blend modes. 

While this package can be used to quickly add a cinematic effect to tastefully chosen elements of any SwiftUI application, best results are achieved using content colors designed around the advantages and challenges of HDR.
 
 # License
This project is licensed under the MIT License - see the LICENSE file for details.
