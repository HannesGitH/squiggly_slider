## 1.0.0

* initial release
* squiggly slider widget `SquigglySlider`
* same API as `Slider` with 3 added parameters to control squigglyness
* only lhs of track can be squiggly in current version
* docstrings not yet modified

## 1.0.1

* better docs
* example

## 1.0.2

* added screenshot
* removed sdk version constraint


## 1.0.3

* increased upper sdk version constraint to get more pub points ;)

## 1.0.4

* dispose phase animation controller

## 1.0.5

* added `useLineThumb` parameter to optionally closer align with A13s Media Control Slider Design (thanks [@GioPan04](https://github.com/GioPan04)

## 2.0.0

**Breaking:** migrated from `package:flutter/material.dart` to `package:material_ui/material_ui.dart`,
following the Material/Cupertino package split in Flutter 3.47.

* `SquigglySlider` now extends `material_ui`'s `Slider` instead of the Flutter SDK's. Apps that
  have not yet migrated to `package:material_ui` will hit "No Material widget found" at runtime,
  because the slider looks up a `material_ui` `Material` ancestor rather than the legacy one.
* `SliderThemeData`, `SliderTrackShape` and `SliderComponentShape` in the public API are now the
  `material_ui` types.
* To migrate, run `dart fix --apply --code=migrate_design_widgets` in your app. Apps that cannot
  migrate yet should stay on 1.0.5.
* Requires Dart >= 3.12 and Flutter >= 3.44.

Also in this release:

* Fixed a crash when `squiggleAmplitude` was set while `squiggleWavelength` was left at its default
  of `0.0`: the track shape divided by the wavelength, producing NaN offsets and an assertion in
  `dart:ui`. Either value being unset now draws a plain track. (Present since 1.0.0.)
* Added widget tests; the package previously shipped with none.
