<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

# Flutter Package to add the Squiggly Seekbar (introduced in Android 13 for the Media Player) as a Widget 

## Features

Flutter rebuild of the Squiggly Seekbar introduced in Android 13 for the Media Player.

![Squiggly Seekbar Sample](./assets/sample.mov)

## Getting started

`flutter pub add squiggly_slider`
or manually add the dependency to your `pubspec.yaml` file.

```yaml
dependencies:
  squiggly_slider: ^0.0.1
```

## Usage

import the package

```dart
import 'package:squiggly_slider/squiggly_slider.dart';
```

and then use it as a drop in replacement for the normal slider

```dart
SquigglySlider(
    //... normal Slider Widget properties ...
    squiggleAmplitude: 5.0,
    squiggleWavelength: 5.0,
    squiggleSpeed: 0.3,
),
```

## Additional information

contributions (PRs) are welcome.
