# SwiftEDR

A clean, convenient and performant mini-framework to bring EDR (extended dynamic range) and HDR (high dynamic range) to any SwiftUI view.


## Introduction

SwiftEDR simplifies the somewhat intricate details related to using extended and high dynamic range bit depths and color spaces within SwiftUI. It also comes with a modest suite of common HDR accompaniments like Tone Mapping and Bloom, which will hopefully expand over time.

#### Supported Modes 

* SDR (Standard Dynamic Range) – same color range as standard views, except you can apply a bloom effect. 
* EDR (Extended Dynamic Range) – extended color range with higher precision color math, bloom and tone mapping support.
* HDR (Extended Dynamic Range) – extended color range with higher precision color math, bloom and tone mapping support, and special display handling on compatible hardware.

#### Example App
Take a peek at what kind of visual results you can expect! We encourage you to open the SwiftEDRExample app and experience the interactive demo. To access all controls, run on an iPad family device. 

After all, as a picture is worth a thousand words, with this kind of framework. The demo UI controls are a good way to study the visual behavior of the various picture modes and effects.


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

In either case, the `Picture` model features heavily, so let's take a quick look.

### Picture Model 

The `Picture` model is of particular significance. Its role includes:
* Configuring the primary EDR mode along with related behaviors and effects.
* Vending colors and other values that are calibrated for the selected EDR mode. 

You can use `Picture.Defaults` to quickly select a preset, or else customize your own effects and display attributes. Note that little time has yet been spent on tuning Defaults, plus it may be best to tune the Bloom effect, in particular, to your specific content and aesthetics.

### EDR Modifier View Modifier

This view modifier allows you to apply EDR behaviors (defined by a Picture) to a specific view.

```swift
AnimatedHeroView()
    // Make it cinematic
    .modifier(EDRModifier(picture: .Defaults.hdrBloom))
```

### EDRCanvas View

This is a more-or-less drop in replacement for SwiftUI Canvas. But why bother, you ask? Why not just use that sweet view modifier?

Well, the reason is simply to ensure the Canvas is properly configured for the current EDR mode, which can be fiddlesome to get right. 

For now, I'm out of time to add examples here, so please see the SwiftEDRExample app for usage.
 
 
 # License
This project is licensed under the MIT License - see the LICENSE file for details.
