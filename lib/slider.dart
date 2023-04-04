library slider;
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter/services.dart';

// Examples can assume:
// int _dollars = 0;
// int _duelCommandment = 1;
// void setState(VoidCallback fn) { }

/// [SquigglySlider] uses this callback to paint the value indicator on the overlay.
///
/// Since the value indicator is painted on the Overlay; this method paints the
/// value indicator in a [RenderBox] that appears in the [Overlay].
typedef PaintValueIndicator = void Function(
    PaintingContext context, Offset offset);

/// A Material Design slider.
///
/// Used to select from a range of values.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=ufb4gIPDmEs}
///
/// {@tool dartpad}
/// ![A legacy slider widget, consisting of 5 divisions and showing the default value
/// indicator.](https://flutter.github.io/assets-for-api-docs/assets/material/slider.png)
///
/// The Sliders value is part of the Stateful widget subclass to change the value
/// setState was called.
///
/// ** See code in examples/api/lib/material/slider/slider.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This sample shows the creation of a [SquigglySlider] using [ThemeData.useMaterial3] flag,
/// as described in: https://m3.material.io/components/sliders/overview.
///
/// ** See code in examples/api/lib/material/slider/slider.1.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This example shows a [SquigglySlider] widget using the [SquigglySlider.secondaryTrackValue]
/// to show a secondary track in the slider.
///
/// ** See code in examples/api/lib/material/slider/slider.2.dart **
/// {@end-tool}
///
/// A slider can be used to select from either a continuous or a discrete set of
/// values. The default is to use a continuous range of values from [min] to
/// [max]. To use discrete values, use a non-null value for [divisions], which
/// indicates the number of discrete intervals. For example, if [min] is 0.0 and
/// [max] is 50.0 and [divisions] is 5, then the slider can take on the
/// discrete values 0.0, 10.0, 20.0, 30.0, 40.0, and 50.0.
///
/// The terms for the parts of a slider are:
///
///  * The "thumb", which is a shape that slides horizontally when the user
///    drags it.
///  * The "track", which is the line that the slider thumb slides along.
///  * The "value indicator", which is a shape that pops up when the user
///    is dragging the thumb to indicate the value being selected.
///  * The "active" side of the slider is the side between the thumb and the
///    minimum value.
///  * The "inactive" side of the slider is the side between the thumb and the
///    maximum value.
///
/// The slider will be disabled if [onChanged] is null or if the range given by
/// [min]..[max] is empty (i.e. if [min] is equal to [max]).
///
/// The slider widget itself does not maintain any state. Instead, when the state
/// of the slider changes, the widget calls the [onChanged] callback. Most
/// widgets that use a slider will listen for the [onChanged] callback and
/// rebuild the slider with a new [value] to update the visual appearance of the
/// slider. To know when the value starts to change, or when it is done
/// changing, set the optional callbacks [onChangeStart] and/or [onChangeEnd].
///
/// By default, a slider will be as wide as possible, centered vertically. When
/// given unbounded constraints, it will attempt to make the track 144 pixels
/// wide (with margins on each side) and will shrink-wrap vertically.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// Requires one of its ancestors to be a [MediaQuery] widget. Typically, these
/// are introduced by the [MaterialApp] or [WidgetsApp] widget at the top of
/// your application widget tree.
///
/// To determine how it should be displayed (e.g. colors, thumb shape, etc.),
/// a slider uses the [SliderThemeData] available from either a [SliderTheme]
/// widget or the [ThemeData.sliderTheme] a [Theme] widget above it in the
/// widget tree. You can also override some of the colors with the [activeColor]
/// and [inactiveColor] properties, although more fine-grained control of the
/// look is achieved using a [SliderThemeData].
///
/// See also:
///
///  * [SliderTheme] and [SliderThemeData] for information about controlling
///    the visual appearance of the slider.
///  * [Radio], for selecting among a set of explicit values.
///  * [Checkbox] and [Switch], for toggling a particular value on or off.
///  * <https://material.io/design/components/sliders.html>
///  * [MediaQuery], from which the text scale factor is obtained.
class SquigglySlider extends Slider {
  /// Creates a Material Design slider.
  ///
  /// The slider itself does not maintain any state. Instead, when the state of
  /// the slider changes, the widget calls the [onChanged] callback. Most
  /// widgets that use a slider will listen for the [onChanged] callback and
  /// rebuild the slider with a new [value] to update the visual appearance of
  /// the slider.
  ///
  /// * [value] determines currently selected value for this slider.
  /// * [onChanged] is called while the user is selecting a new value for the
  ///   slider.
  /// * [onChangeStart] is called when the user starts to select a new value for
  ///   the slider.
  /// * [onChangeEnd] is called when the user is done selecting a new value for
  ///   the slider.
  ///
  /// You can override some of the colors with the [activeColor] and
  /// [inactiveColor] properties, although more fine-grained control of the
  /// appearance is achieved using a [SliderThemeData].
  const SquigglySlider({
    super.key,
    required super.value,
    super.secondaryTrackValue,
    required super.onChanged,
    super.onChangeStart,
    super.onChangeEnd,
    super.min = 0.0,
    super.max = 1.0,
    super.divisions,
    super.label,
    super.activeColor,
    super.inactiveColor,
    super.secondaryActiveColor,
    super.thumbColor,
    super.overlayColor,
    super.mouseCursor,
    super.semanticFormatterCallback,
    super.focusNode,
    super.autofocus = false,
    this.squiggleAmplitude = 0.0,
    this.squiggleWavelength = 0.0,
    this.squiggleSpeed = 1.0,
  });

  final double squiggleAmplitude;
  final double squiggleWavelength;
  final double squiggleSpeed;

  @override
  State<SquigglySlider> createState() => _SquigglySliderState();
}

class _SquigglySliderState extends State<SquigglySlider>
    with TickerProviderStateMixin {
  static const Duration enableAnimationDuration = Duration(milliseconds: 75);
  static const Duration valueIndicatorAnimationDuration =
      Duration(milliseconds: 100);

  // Animation controller that is run when the overlay (a.k.a radial reaction)
  // is shown in response to user interaction.
  late AnimationController overlayController;
  // Animation controller that is run when the value indicator is being shown
  // or hidden.
  late AnimationController valueIndicatorController;
  // Animation controller that is run when enabling/disabling the slider.
  late AnimationController enableController;
  // Animation controller that is run when transitioning between one value
  // and the next on a discrete slider.
  late AnimationController positionController;
  Timer? interactionTimer;

  late AnimationController squigglePhaseFactorController;

  final GlobalKey _renderObjectKey = GlobalKey();

  // Keyboard mapping for a focused slider.
  static const Map<ShortcutActivator, Intent> _traditionalNavShortcutMap =
      <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.arrowUp): _AdjustSliderIntent.up(),
    SingleActivator(LogicalKeyboardKey.arrowDown): _AdjustSliderIntent.down(),
    SingleActivator(LogicalKeyboardKey.arrowLeft): _AdjustSliderIntent.left(),
    SingleActivator(LogicalKeyboardKey.arrowRight): _AdjustSliderIntent.right(),
  };

  // Keyboard mapping for a focused slider when using directional navigation.
  // The vertical inputs are not handled to allow navigating out of the slider.
  static const Map<ShortcutActivator, Intent> _directionalNavShortcutMap =
      <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.arrowLeft): _AdjustSliderIntent.left(),
    SingleActivator(LogicalKeyboardKey.arrowRight): _AdjustSliderIntent.right(),
  };

  // Action mapping for a focused slider.
  late Map<Type, Action<Intent>> _actionMap;

  bool get _enabled => widget.onChanged != null;
  // Value Indicator Animation that appears on the Overlay.
  PaintValueIndicator? paintValueIndicator;

  bool _dragging = false;

  FocusNode? _focusNode;
  FocusNode get focusNode => widget.focusNode ?? _focusNode!;

  @override
  void initState() {
    super.initState();
    overlayController = AnimationController(
      duration: kRadialReactionDuration,
      vsync: this,
    );
    valueIndicatorController = AnimationController(
      duration: valueIndicatorAnimationDuration,
      vsync: this,
    );
    enableController = AnimationController(
      duration: enableAnimationDuration,
      vsync: this,
    );
    positionController = AnimationController(
      duration: Duration.zero,
      vsync: this,
    );
    squigglePhaseFactorController = AnimationController(
      duration: Duration(milliseconds: (1000 / widget.squiggleSpeed).round()),
      vsync: this,
    );
    squigglePhaseFactorController.repeat(min: 0, max: 1);
    enableController.value = widget.onChanged != null ? 1.0 : 0.0;
    positionController.value = _convert(widget.value);
    _actionMap = <Type, Action<Intent>>{
      _AdjustSliderIntent: CallbackAction<_AdjustSliderIntent>(
        onInvoke: _actionHandler,
      ),
    };
    if (widget.focusNode == null) {
      // Only create a new node if the widget doesn't have one.
      _focusNode ??= FocusNode();
    }
  }

  @override
  void dispose() {
    interactionTimer?.cancel();
    overlayController.dispose();
    valueIndicatorController.dispose();
    enableController.dispose();
    positionController.dispose();
    if (overlayEntry != null) {
      overlayEntry!.remove();
      overlayEntry = null;
    }
    _focusNode?.dispose();
    super.dispose();
  }

  void _handleChanged(double value) {
    assert(widget.onChanged != null);
    final double lerpValue = _lerp(value);
    if (lerpValue != widget.value) {
      widget.onChanged!(lerpValue);
      _focusNode?.requestFocus();
    }
  }

  void _handleDragStart(double value) {
    _dragging = true;
    widget.onChangeStart?.call(_lerp(value));
  }

  void _handleDragEnd(double value) {
    _dragging = false;
    widget.onChangeEnd?.call(_lerp(value));
  }

  void _actionHandler(_AdjustSliderIntent intent) {
    final _RenderSlider renderSlider =
        _renderObjectKey.currentContext!.findRenderObject()! as _RenderSlider;
    final TextDirection textDirection =
        Directionality.of(_renderObjectKey.currentContext!);
    switch (intent.type) {
      case _SliderAdjustmentType.right:
        switch (textDirection) {
          case TextDirection.rtl:
            renderSlider.decreaseAction();
            break;
          case TextDirection.ltr:
            renderSlider.increaseAction();
            break;
        }
        break;
      case _SliderAdjustmentType.left:
        switch (textDirection) {
          case TextDirection.rtl:
            renderSlider.increaseAction();
            break;
          case TextDirection.ltr:
            renderSlider.decreaseAction();
            break;
        }
        break;
      case _SliderAdjustmentType.up:
        renderSlider.increaseAction();
        break;
      case _SliderAdjustmentType.down:
        renderSlider.decreaseAction();
        break;
    }
  }

  bool _focused = false;
  void _handleFocusHighlightChanged(bool focused) {
    if (focused != _focused) {
      setState(() {
        _focused = focused;
      });
    }
  }

  bool _hovering = false;
  void _handleHoverChanged(bool hovering) {
    if (hovering != _hovering) {
      setState(() {
        _hovering = hovering;
      });
    }
  }

  // Returns a number between min and max, proportional to value, which must
  // be between 0.0 and 1.0.
  double _lerp(double value) {
    assert(value >= 0.0);
    assert(value <= 1.0);
    return value * (widget.max - widget.min) + widget.min;
  }

  double _discretize(double value) {
    assert(widget.divisions != null);
    assert(value >= 0.0 && value <= 1.0);

    final int divisions = widget.divisions!;
    return (value * divisions).round() / divisions;
  }

  double _convert(double value) {
    double ret = _unlerp(value);
    if (widget.divisions != null) {
      ret = _discretize(ret);
    }
    return ret;
  }

  // Returns a number between 0.0 and 1.0, given a value between min and max.
  double _unlerp(double value) {
    assert(value <= widget.max);
    assert(value >= widget.min);
    return widget.max > widget.min
        ? (value - widget.min) / (widget.max - widget.min)
        : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    assert(debugCheckHasMediaQuery(context));
    return _buildMaterialSlider(context);
  }

  Widget _buildMaterialSlider(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    SliderThemeData sliderTheme = SliderTheme.of(context);
    final SliderThemeData defaults = theme.useMaterial3
        ? _SliderDefaultsM3(context)
        : _SliderDefaultsM2(context);

    // If the widget has active or inactive colors specified, then we plug them
    // in to the slider theme as best we can. If the developer wants more
    // control than that, then they need to use a SliderTheme. The default
    // colors come from the ThemeData.colorScheme. These colors, along with
    // the default shapes and text styles are aligned to the Material
    // Guidelines.

    const SliderTrackShape defaultTrackShape = RoundedRectSliderTrackShape();
    const SliderTickMarkShape defaultTickMarkShape = RoundSliderTickMarkShape();
    const SliderComponentShape defaultOverlayShape = RoundSliderOverlayShape();
    const SliderComponentShape defaultThumbShape = RoundSliderThumbShape();
    final SliderComponentShape defaultValueIndicatorShape =
        defaults.valueIndicatorShape!;
    const ShowValueIndicator defaultShowValueIndicator =
        ShowValueIndicator.onlyForDiscrete;

    final Set<MaterialState> states = <MaterialState>{
      if (!_enabled) MaterialState.disabled,
      if (_hovering) MaterialState.hovered,
      if (_focused) MaterialState.focused,
      if (_dragging) MaterialState.dragged,
    };

    // The value indicator's color is not the same as the thumb and active track
    // (which can be defined by activeColor) if the
    // RectangularSliderValueIndicatorShape is used. In all other cases, the
    // value indicator is assumed to be the same as the active color.
    final SliderComponentShape valueIndicatorShape =
        sliderTheme.valueIndicatorShape ?? defaultValueIndicatorShape;
    final Color valueIndicatorColor;
    if (valueIndicatorShape is RectangularSliderValueIndicatorShape) {
      valueIndicatorColor = sliderTheme.valueIndicatorColor ??
          Color.alphaBlend(theme.colorScheme.onSurface.withOpacity(0.60),
              theme.colorScheme.surface.withOpacity(0.90));
    } else {
      valueIndicatorColor = widget.activeColor ??
          sliderTheme.valueIndicatorColor ??
          theme.colorScheme.primary;
    }

    Color? effectiveOverlayColor() {
      return widget.overlayColor?.resolve(states) ??
          widget.activeColor?.withOpacity(0.12) ??
          MaterialStateProperty.resolveAs<Color?>(
              sliderTheme.overlayColor, states) ??
          MaterialStateProperty.resolveAs<Color?>(
              defaults.overlayColor, states);
    }

    sliderTheme = sliderTheme.copyWith(
      trackHeight: sliderTheme.trackHeight ?? defaults.trackHeight,
      activeTrackColor: widget.activeColor ??
          sliderTheme.activeTrackColor ??
          defaults.activeTrackColor,
      inactiveTrackColor: widget.inactiveColor ??
          sliderTheme.inactiveTrackColor ??
          defaults.inactiveTrackColor,
      secondaryActiveTrackColor: widget.secondaryActiveColor ??
          sliderTheme.secondaryActiveTrackColor ??
          defaults.secondaryActiveTrackColor,
      disabledActiveTrackColor: sliderTheme.disabledActiveTrackColor ??
          defaults.disabledActiveTrackColor,
      disabledInactiveTrackColor: sliderTheme.disabledInactiveTrackColor ??
          defaults.disabledInactiveTrackColor,
      disabledSecondaryActiveTrackColor:
          sliderTheme.disabledSecondaryActiveTrackColor ??
              defaults.disabledSecondaryActiveTrackColor,
      activeTickMarkColor: widget.inactiveColor ??
          sliderTheme.activeTickMarkColor ??
          defaults.activeTickMarkColor,
      inactiveTickMarkColor: widget.activeColor ??
          sliderTheme.inactiveTickMarkColor ??
          defaults.inactiveTickMarkColor,
      disabledActiveTickMarkColor: sliderTheme.disabledActiveTickMarkColor ??
          defaults.disabledActiveTickMarkColor,
      disabledInactiveTickMarkColor:
          sliderTheme.disabledInactiveTickMarkColor ??
              defaults.disabledInactiveTickMarkColor,
      thumbColor: widget.thumbColor ??
          widget.activeColor ??
          sliderTheme.thumbColor ??
          defaults.thumbColor,
      disabledThumbColor:
          sliderTheme.disabledThumbColor ?? defaults.disabledThumbColor,
      overlayColor: effectiveOverlayColor(),
      valueIndicatorColor: valueIndicatorColor,
      trackShape: sliderTheme.trackShape ?? defaultTrackShape,
      tickMarkShape: sliderTheme.tickMarkShape ?? defaultTickMarkShape,
      thumbShape: sliderTheme.thumbShape ?? defaultThumbShape,
      overlayShape: sliderTheme.overlayShape ?? defaultOverlayShape,
      valueIndicatorShape: valueIndicatorShape,
      showValueIndicator:
          sliderTheme.showValueIndicator ?? defaultShowValueIndicator,
      valueIndicatorTextStyle: sliderTheme.valueIndicatorTextStyle ??
          defaults.valueIndicatorTextStyle,
    );
    final MouseCursor effectiveMouseCursor =
        MaterialStateProperty.resolveAs<MouseCursor?>(
                widget.mouseCursor, states) ??
            sliderTheme.mouseCursor?.resolve(states) ??
            MaterialStateMouseCursor.clickable.resolve(states);

    // This size is used as the max bounds for the painting of the value
    // indicators It must be kept in sync with the function with the same name
    // in range_slider.dart.
    Size screenSize() => MediaQuery.of(context).size;

    VoidCallback? handleDidGainAccessibilityFocus;
    switch (theme.platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        break;
      case TargetPlatform.windows:
        handleDidGainAccessibilityFocus = () {
          // Automatically activate the slider when it receives a11y focus.
          if (!focusNode.hasFocus && focusNode.canRequestFocus) {
            focusNode.requestFocus();
          }
        };
        break;
    }

    final Map<ShortcutActivator, Intent> shortcutMap;
    switch (MediaQuery.of(context).navigationMode) {
      case NavigationMode.directional:
        shortcutMap = _directionalNavShortcutMap;
        break;
      case NavigationMode.traditional:
        shortcutMap = _traditionalNavShortcutMap;
        break;
    }

    final double textScaleFactor = theme.useMaterial3
        // TODO(tahatesser): This is an eye-balled value.
        // This needs to be updated when accessibility
        // guidelines are available on the material specs page
        // https://m3.material.io/components/sliders/accessibility.
        ? math.min(MediaQuery.of(context).textScaleFactor, 1.3)
        : MediaQuery.of(context).textScaleFactor;

    return Semantics(
      container: true,
      slider: true,
      onDidGainAccessibilityFocus: handleDidGainAccessibilityFocus,
      child: FocusableActionDetector(
        actions: _actionMap,
        shortcuts: shortcutMap,
        focusNode: focusNode,
        autofocus: widget.autofocus,
        enabled: _enabled,
        onShowFocusHighlight: _handleFocusHighlightChanged,
        onShowHoverHighlight: _handleHoverChanged,
        mouseCursor: effectiveMouseCursor,
        child: CompositedTransformTarget(
          link: _layerLink,
          child: _SquigglySliderRenderObjectWidget(
            key: _renderObjectKey,
            value: _convert(widget.value),
            secondaryTrackValue: (widget.secondaryTrackValue != null)
                ? _convert(widget.secondaryTrackValue!)
                : null,
            divisions: widget.divisions,
            label: widget.label,
            sliderTheme: sliderTheme,
            textScaleFactor: textScaleFactor,
            screenSize: screenSize(),
            onChanged: (widget.onChanged != null) && (widget.max > widget.min)
                ? _handleChanged
                : null,
            onChangeStart: _handleDragStart,
            onChangeEnd: _handleDragEnd,
            state: this,
            semanticFormatterCallback: widget.semanticFormatterCallback,
            hasFocus: _focused,
            hovering: _hovering,
            amplitude: widget.squiggleAmplitude,
            frequency: widget.squiggleWavelength,
            phaseFactor: squigglePhaseFactorController.value,
          ),
        ),
      ),
    );
  }

  final LayerLink _layerLink = LayerLink();

  OverlayEntry? overlayEntry;

  void showValueIndicator() {
    if (overlayEntry == null) {
      overlayEntry = OverlayEntry(
        builder: (BuildContext context) {
          return CompositedTransformFollower(
            link: _layerLink,
            child: _ValueIndicatorRenderObjectWidget(
              state: this,
            ),
          );
        },
      );
      Overlay.of(context, debugRequiredFor: widget).insert(overlayEntry!);
    }
  }
}

class _SquigglySliderRenderObjectWidget extends LeafRenderObjectWidget {
  const _SquigglySliderRenderObjectWidget({
    super.key,
    required this.value,
    required this.secondaryTrackValue,
    required this.divisions,
    required this.label,
    required this.sliderTheme,
    required this.textScaleFactor,
    required this.screenSize,
    required this.onChanged,
    required this.onChangeStart,
    required this.onChangeEnd,
    required this.state,
    required this.semanticFormatterCallback,
    required this.hasFocus,
    required this.hovering,
    required this.amplitude,
    required this.frequency,
    required this.phaseFactor,
  });

  final double value;
  final double? secondaryTrackValue;
  final int? divisions;
  final String? label;
  final SliderThemeData sliderTheme;
  final double textScaleFactor;
  final Size screenSize;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final SemanticFormatterCallback? semanticFormatterCallback;
  final _SquigglySliderState state;
  final bool hasFocus;
  final bool hovering;
  final double amplitude;
  final double frequency;
  final double phaseFactor;

  @override
  _RenderSlider createRenderObject(BuildContext context) {
    return _RenderSlider(
      value: value,
      secondaryTrackValue: secondaryTrackValue,
      divisions: divisions,
      label: label,
      sliderTheme: sliderTheme,
      textScaleFactor: textScaleFactor,
      screenSize: screenSize,
      onChanged: onChanged,
      onChangeStart: onChangeStart,
      onChangeEnd: onChangeEnd,
      state: state,
      textDirection: Directionality.of(context),
      semanticFormatterCallback: semanticFormatterCallback,
      platform: Theme.of(context).platform,
      hasFocus: hasFocus,
      hovering: hovering,
      gestureSettings: MediaQuery.of(context).gestureSettings,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderSlider renderObject) {
    renderObject
      // We should update the `divisions` ahead of `value`, because the `value`
      // setter dependent on the `divisions`.
      ..divisions = divisions
      ..value = value
      ..secondaryTrackValue = secondaryTrackValue
      ..label = label
      ..sliderTheme = sliderTheme
      ..textScaleFactor = textScaleFactor
      ..screenSize = screenSize
      ..onChanged = onChanged
      ..onChangeStart = onChangeStart
      ..onChangeEnd = onChangeEnd
      ..textDirection = Directionality.of(context)
      ..semanticFormatterCallback = semanticFormatterCallback
      ..platform = Theme.of(context).platform
      ..hasFocus = hasFocus
      ..hovering = hovering
      ..gestureSettings = MediaQuery.of(context).gestureSettings;
    // Ticker provider cannot change since there's a 1:1 relationship between
    // the _SliderRenderObjectWidget object and the _SliderState object.
  }
}

class _RenderSlider extends RenderBox with RelayoutWhenSystemFontsChangeMixin {
  _RenderSlider({
    required double value,
    required double? secondaryTrackValue,
    required int? divisions,
    required String? label,
    required SliderThemeData sliderTheme,
    required double textScaleFactor,
    required Size screenSize,
    required TargetPlatform platform,
    required ValueChanged<double>? onChanged,
    required SemanticFormatterCallback? semanticFormatterCallback,
    required this.onChangeStart,
    required this.onChangeEnd,
    required _SquigglySliderState state,
    required TextDirection textDirection,
    required bool hasFocus,
    required bool hovering,
    required DeviceGestureSettings gestureSettings,
  })  : assert(value != null && value >= 0.0 && value <= 1.0),
        assert(secondaryTrackValue == null ||
            (secondaryTrackValue >= 0.0 && secondaryTrackValue <= 1.0)),
        assert(state != null),
        assert(textDirection != null),
        _platform = platform,
        _semanticFormatterCallback = semanticFormatterCallback,
        _label = label,
        _value = value,
        _secondaryTrackValue = secondaryTrackValue,
        _divisions = divisions,
        _sliderTheme = sliderTheme,
        _textScaleFactor = textScaleFactor,
        _screenSize = screenSize,
        _onChanged = onChanged,
        _state = state,
        _textDirection = textDirection,
        _hasFocus = hasFocus,
        _hovering = hovering {
    _updateLabelPainter();
    final GestureArenaTeam team = GestureArenaTeam();
    _drag = HorizontalDragGestureRecognizer()
      ..team = team
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _endInteraction
      ..gestureSettings = gestureSettings;
    _tap = TapGestureRecognizer()
      ..team = team
      ..onTapDown = _handleTapDown
      ..onTapUp = _handleTapUp
      ..gestureSettings = gestureSettings;
    _overlayAnimation = CurvedAnimation(
      parent: _state.overlayController,
      curve: Curves.fastOutSlowIn,
    );
    _valueIndicatorAnimation = CurvedAnimation(
      parent: _state.valueIndicatorController,
      curve: Curves.fastOutSlowIn,
    )..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.dismissed &&
            _state.overlayEntry != null) {
          _state.overlayEntry!.remove();
          _state.overlayEntry = null;
        }
      });
    _enableAnimation = CurvedAnimation(
      parent: _state.enableController,
      curve: Curves.easeInOut,
    );
  }
  static const Duration _positionAnimationDuration = Duration(milliseconds: 75);
  static const Duration _minimumInteractionTime = Duration(milliseconds: 500);

  // This value is the touch target, 48, multiplied by 3.
  static const double _minPreferredTrackWidth = 144.0;

  // Compute the largest width and height needed to paint the slider shapes,
  // other than the track shape. It is assumed that these shapes are vertically
  // centered on the track.
  double get _maxSliderPartWidth =>
      _sliderPartSizes.map((Size size) => size.width).reduce(math.max);
  double get _maxSliderPartHeight =>
      _sliderPartSizes.map((Size size) => size.height).reduce(math.max);
  List<Size> get _sliderPartSizes => <Size>[
        _sliderTheme.overlayShape!.getPreferredSize(isInteractive, isDiscrete),
        _sliderTheme.thumbShape!.getPreferredSize(isInteractive, isDiscrete),
        _sliderTheme.tickMarkShape!.getPreferredSize(
            isEnabled: isInteractive, sliderTheme: sliderTheme),
      ];
  double get _minPreferredTrackHeight => _sliderTheme.trackHeight!;

  final _SquigglySliderState _state;
  late Animation<double> _overlayAnimation;
  late Animation<double> _valueIndicatorAnimation;
  late Animation<double> _enableAnimation;
  final TextPainter _labelPainter = TextPainter();
  late HorizontalDragGestureRecognizer _drag;
  late TapGestureRecognizer _tap;
  bool _active = false;
  double _currentDragValue = 0.0;
  Rect? overlayRect;

  // This rect is used in gesture calculations, where the gesture coordinates
  // are relative to the sliders origin. Therefore, the offset is passed as
  // (0,0).
  Rect get _trackRect => _sliderTheme.trackShape!.getPreferredRect(
        parentBox: this,
        sliderTheme: _sliderTheme,
        isDiscrete: false,
      );

  bool get isInteractive => onChanged != null;

  bool get isDiscrete => divisions != null && divisions! > 0;

  double get value => _value;
  double _value;
  set value(double newValue) {
    assert(newValue != null && newValue >= 0.0 && newValue <= 1.0);
    final double convertedValue = isDiscrete ? _discretize(newValue) : newValue;
    if (convertedValue == _value) {
      return;
    }
    _value = convertedValue;
    if (isDiscrete) {
      // Reset the duration to match the distance that we're traveling, so that
      // whatever the distance, we still do it in _positionAnimationDuration,
      // and if we get re-targeted in the middle, it still takes that long to
      // get to the new location.
      final double distance = (_value - _state.positionController.value).abs();
      _state.positionController.duration = distance != 0.0
          ? _positionAnimationDuration * (1.0 / distance)
          : Duration.zero;
      _state.positionController
          .animateTo(convertedValue, curve: Curves.easeInOut);
    } else {
      _state.positionController.value = convertedValue;
    }
    markNeedsSemanticsUpdate();
  }

  double? get secondaryTrackValue => _secondaryTrackValue;
  double? _secondaryTrackValue;
  set secondaryTrackValue(double? newValue) {
    assert(newValue == null || (newValue >= 0.0 && newValue <= 1.0));
    if (newValue == _secondaryTrackValue) {
      return;
    }
    _secondaryTrackValue = newValue;
    markNeedsSemanticsUpdate();
  }

  DeviceGestureSettings? get gestureSettings => _drag.gestureSettings;
  set gestureSettings(DeviceGestureSettings? gestureSettings) {
    _drag.gestureSettings = gestureSettings;
    _tap.gestureSettings = gestureSettings;
  }

  TargetPlatform _platform;
  TargetPlatform get platform => _platform;
  set platform(TargetPlatform value) {
    if (_platform == value) {
      return;
    }
    _platform = value;
    markNeedsSemanticsUpdate();
  }

  SemanticFormatterCallback? _semanticFormatterCallback;
  SemanticFormatterCallback? get semanticFormatterCallback =>
      _semanticFormatterCallback;
  set semanticFormatterCallback(SemanticFormatterCallback? value) {
    if (_semanticFormatterCallback == value) {
      return;
    }
    _semanticFormatterCallback = value;
    markNeedsSemanticsUpdate();
  }

  int? get divisions => _divisions;
  int? _divisions;
  set divisions(int? value) {
    if (value == _divisions) {
      return;
    }
    _divisions = value;
    markNeedsPaint();
  }

  String? get label => _label;
  String? _label;
  set label(String? value) {
    if (value == _label) {
      return;
    }
    _label = value;
    _updateLabelPainter();
  }

  SliderThemeData get sliderTheme => _sliderTheme;
  SliderThemeData _sliderTheme;
  set sliderTheme(SliderThemeData value) {
    if (value == _sliderTheme) {
      return;
    }
    _sliderTheme = value;
    markNeedsPaint();
  }

  double get textScaleFactor => _textScaleFactor;
  double _textScaleFactor;
  set textScaleFactor(double value) {
    if (value == _textScaleFactor) {
      return;
    }
    _textScaleFactor = value;
    _updateLabelPainter();
  }

  Size get screenSize => _screenSize;
  Size _screenSize;
  set screenSize(Size value) {
    if (value == _screenSize) {
      return;
    }
    _screenSize = value;
    markNeedsPaint();
  }

  ValueChanged<double>? get onChanged => _onChanged;
  ValueChanged<double>? _onChanged;
  set onChanged(ValueChanged<double>? value) {
    if (value == _onChanged) {
      return;
    }
    final bool wasInteractive = isInteractive;
    _onChanged = value;
    if (wasInteractive != isInteractive) {
      if (isInteractive) {
        _state.enableController.forward();
      } else {
        _state.enableController.reverse();
      }
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  ValueChanged<double>? onChangeStart;
  ValueChanged<double>? onChangeEnd;

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    assert(value != null);
    if (value == _textDirection) {
      return;
    }
    _textDirection = value;
    _updateLabelPainter();
  }

  /// True if this slider has the input focus.
  bool get hasFocus => _hasFocus;
  bool _hasFocus;
  set hasFocus(bool value) {
    assert(value != null);
    if (value == _hasFocus) {
      return;
    }
    _hasFocus = value;
    _updateForFocus(_hasFocus);
    markNeedsSemanticsUpdate();
  }

  /// True if this slider is being hovered over by a pointer.
  bool get hovering => _hovering;
  bool _hovering;
  set hovering(bool value) {
    assert(value != null);
    if (value == _hovering) {
      return;
    }
    _hovering = value;
    _updateForHover(_hovering);
  }

  /// True if the slider is interactive and the slider thumb is being
  /// hovered over by a pointer.
  bool _hoveringThumb = false;
  bool get hoveringThumb => _hoveringThumb;
  set hoveringThumb(bool value) {
    assert(value != null);
    if (value == _hoveringThumb) {
      return;
    }
    _hoveringThumb = value;
    _updateForHover(_hovering);
  }

  void _updateForFocus(bool focused) {
    if (focused) {
      _state.overlayController.forward();
      if (showValueIndicator) {
        _state.valueIndicatorController.forward();
      }
    } else {
      _state.overlayController.reverse();
      if (showValueIndicator) {
        _state.valueIndicatorController.reverse();
      }
    }
  }

  void _updateForHover(bool hovered) {
    // Only show overlay when pointer is hovering the thumb.
    if (hovered && hoveringThumb) {
      _state.overlayController.forward();
    } else {
      // Only remove overlay when Slider is unfocused.
      if (!hasFocus) {
        _state.overlayController.reverse();
      }
    }
  }

  bool get showValueIndicator {
    switch (_sliderTheme.showValueIndicator!) {
      case ShowValueIndicator.onlyForDiscrete:
        return isDiscrete;
      case ShowValueIndicator.onlyForContinuous:
        return !isDiscrete;
      case ShowValueIndicator.always:
        return true;
      case ShowValueIndicator.never:
        return false;
    }
  }

  double get _adjustmentUnit {
    switch (_platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        // Matches iOS implementation of material slider.
        return 0.1;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        // Matches Android implementation of material slider.
        return 0.05;
    }
  }

  void _updateLabelPainter() {
    if (label != null) {
      _labelPainter
        ..text = TextSpan(
          style: _sliderTheme.valueIndicatorTextStyle,
          text: label,
        )
        ..textDirection = textDirection
        ..textScaleFactor = textScaleFactor
        ..layout();
    } else {
      _labelPainter.text = null;
    }
    // Changing the textDirection can result in the layout changing, because the
    // bidi algorithm might line up the glyphs differently which can result in
    // different ligatures, different shapes, etc. So we always markNeedsLayout.
    markNeedsLayout();
  }

  @override
  void systemFontsDidChange() {
    super.systemFontsDidChange();
    _labelPainter.markNeedsLayout();
    _updateLabelPainter();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _overlayAnimation.addListener(markNeedsPaint);
    _valueIndicatorAnimation.addListener(markNeedsPaint);
    _enableAnimation.addListener(markNeedsPaint);
    _state.positionController.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _overlayAnimation.removeListener(markNeedsPaint);
    _valueIndicatorAnimation.removeListener(markNeedsPaint);
    _enableAnimation.removeListener(markNeedsPaint);
    _state.positionController.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void dispose() {
    _labelPainter.dispose();
    super.dispose();
  }

  double _getValueFromVisualPosition(double visualPosition) {
    switch (textDirection) {
      case TextDirection.rtl:
        return 1.0 - visualPosition;
      case TextDirection.ltr:
        return visualPosition;
    }
  }

  double _getValueFromGlobalPosition(Offset globalPosition) {
    final double visualPosition =
        (globalToLocal(globalPosition).dx - _trackRect.left) / _trackRect.width;
    return _getValueFromVisualPosition(visualPosition);
  }

  double _discretize(double value) {
    double result = clampDouble(value, 0.0, 1.0);
    if (isDiscrete) {
      result = (result * divisions!).round() / divisions!;
    }
    return result;
  }

  void _startInteraction(Offset globalPosition) {
    _state.showValueIndicator();
    if (!_active && isInteractive) {
      _active = true;
      // We supply the *current* value as the start location, so that if we have
      // a tap, it consists of a call to onChangeStart with the previous value and
      // a call to onChangeEnd with the new value.
      onChangeStart?.call(_discretize(value));
      _currentDragValue = _getValueFromGlobalPosition(globalPosition);
      onChanged!(_discretize(_currentDragValue));
      _state.overlayController.forward();
      if (showValueIndicator) {
        _state.valueIndicatorController.forward();
        _state.interactionTimer?.cancel();
        _state.interactionTimer =
            Timer(_minimumInteractionTime * timeDilation, () {
          _state.interactionTimer = null;
          if (!_active &&
              !hasFocus &&
              _state.valueIndicatorController.status ==
                  AnimationStatus.completed) {
            _state.valueIndicatorController.reverse();
          }
        });
      }
    }
  }

  void _endInteraction() {
    if (!_state.mounted) {
      return;
    }

    if (_active && _state.mounted) {
      onChangeEnd?.call(_discretize(_currentDragValue));
      _active = false;
      _currentDragValue = 0.0;
      if (!hasFocus) {
        _state.overlayController.reverse();
      }

      if (showValueIndicator && _state.interactionTimer == null) {
        _state.valueIndicatorController.reverse();
      }
    }
  }

  void _handleDragStart(DragStartDetails details) {
    _startInteraction(details.globalPosition);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_state.mounted) {
      return;
    }

    if (isInteractive) {
      final double valueDelta = details.primaryDelta! / _trackRect.width;
      switch (textDirection) {
        case TextDirection.rtl:
          _currentDragValue -= valueDelta;
          break;
        case TextDirection.ltr:
          _currentDragValue += valueDelta;
          break;
      }
      onChanged!(_discretize(_currentDragValue));
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    _endInteraction();
  }

  void _handleTapDown(TapDownDetails details) {
    _startInteraction(details.globalPosition);
  }

  void _handleTapUp(TapUpDetails details) {
    _endInteraction();
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent && isInteractive) {
      // We need to add the drag first so that it has priority.
      _drag.addPointer(event);
      _tap.addPointer(event);
    }
    if (isInteractive && overlayRect != null) {
      hoveringThumb = overlayRect!.contains(event.localPosition);
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _minPreferredTrackWidth + _maxSliderPartWidth;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _minPreferredTrackWidth + _maxSliderPartWidth;

  @override
  double computeMinIntrinsicHeight(double width) =>
      math.max(_minPreferredTrackHeight, _maxSliderPartHeight);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      math.max(_minPreferredTrackHeight, _maxSliderPartHeight);

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return Size(
      constraints.hasBoundedWidth
          ? constraints.maxWidth
          : _minPreferredTrackWidth + _maxSliderPartWidth,
      constraints.hasBoundedHeight
          ? constraints.maxHeight
          : math.max(_minPreferredTrackHeight, _maxSliderPartHeight),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final double value = _state.positionController.value;
    final double? secondaryValue = _secondaryTrackValue;

    // The visual position is the position of the thumb from 0 to 1 from left
    // to right. In left to right, this is the same as the value, but it is
    // reversed for right to left text.
    final double visualPosition;
    final double? secondaryVisualPosition;
    switch (textDirection) {
      case TextDirection.rtl:
        visualPosition = 1.0 - value;
        secondaryVisualPosition =
            (secondaryValue != null) ? (1.0 - secondaryValue) : null;
        break;
      case TextDirection.ltr:
        visualPosition = value;
        secondaryVisualPosition =
            (secondaryValue != null) ? secondaryValue : null;
        break;
    }

    final Rect trackRect = _sliderTheme.trackShape!.getPreferredRect(
      parentBox: this,
      offset: offset,
      sliderTheme: _sliderTheme,
      isDiscrete: isDiscrete,
    );
    final Offset thumbCenter = Offset(
        trackRect.left + visualPosition * trackRect.width, trackRect.center.dy);
    if (isInteractive) {
      final Size overlaySize =
          sliderTheme.overlayShape!.getPreferredSize(isInteractive, false);
      overlayRect =
          Rect.fromCircle(center: thumbCenter, radius: overlaySize.width / 2.0);
    }
    final Offset? secondaryOffset = (secondaryVisualPosition != null)
        ? Offset(trackRect.left + secondaryVisualPosition * trackRect.width,
            trackRect.center.dy)
        : null;

    //TODO: paint squiggly track?
    _sliderTheme.trackShape!.paint(
      context,
      offset,
      parentBox: this,
      sliderTheme: _sliderTheme,
      enableAnimation: _enableAnimation,
      textDirection: _textDirection,
      thumbCenter: thumbCenter,
      secondaryOffset: secondaryOffset,
      isDiscrete: isDiscrete,
      isEnabled: isInteractive,
    );

    if (!_overlayAnimation.isDismissed) {
      _sliderTheme.overlayShape!.paint(
        context,
        thumbCenter,
        activationAnimation: _overlayAnimation,
        enableAnimation: _enableAnimation,
        isDiscrete: isDiscrete,
        labelPainter: _labelPainter,
        parentBox: this,
        sliderTheme: _sliderTheme,
        textDirection: _textDirection,
        value: _value,
        textScaleFactor: _textScaleFactor,
        sizeWithOverflow: screenSize.isEmpty ? size : screenSize,
      );
    }

    if (isDiscrete) {
      final double tickMarkWidth = _sliderTheme.tickMarkShape!
          .getPreferredSize(
            isEnabled: isInteractive,
            sliderTheme: _sliderTheme,
          )
          .width;
      final double padding = trackRect.height;
      final double adjustedTrackWidth = trackRect.width - padding;
      // If the tick marks would be too dense, don't bother painting them.
      if (adjustedTrackWidth / divisions! >= 3.0 * tickMarkWidth) {
        final double dy = trackRect.center.dy;
        for (int i = 0; i <= divisions!; i++) {
          final double value = i / divisions!;
          // The ticks are mapped to be within the track, so the tick mark width
          // must be subtracted from the track width.
          final double dx =
              trackRect.left + value * adjustedTrackWidth + padding / 2;
          final Offset tickMarkOffset = Offset(dx, dy);
          _sliderTheme.tickMarkShape!.paint(
            context,
            tickMarkOffset,
            parentBox: this,
            sliderTheme: _sliderTheme,
            enableAnimation: _enableAnimation,
            textDirection: _textDirection,
            thumbCenter: thumbCenter,
            isEnabled: isInteractive,
          );
        }
      }
    }

    if (isInteractive &&
        label != null &&
        !_valueIndicatorAnimation.isDismissed) {
      if (showValueIndicator) {
        _state.paintValueIndicator = (PaintingContext context, Offset offset) {
          if (attached) {
            _sliderTheme.valueIndicatorShape!.paint(
              context,
              offset + thumbCenter,
              activationAnimation: _valueIndicatorAnimation,
              enableAnimation: _enableAnimation,
              isDiscrete: isDiscrete,
              labelPainter: _labelPainter,
              parentBox: this,
              sliderTheme: _sliderTheme,
              textDirection: _textDirection,
              value: _value,
              textScaleFactor: textScaleFactor,
              sizeWithOverflow: screenSize.isEmpty ? size : screenSize,
            );
          }
        };
      }
    }

    _sliderTheme.thumbShape!.paint(
      context,
      thumbCenter,
      activationAnimation: _overlayAnimation,
      enableAnimation: _enableAnimation,
      isDiscrete: isDiscrete,
      labelPainter: _labelPainter,
      parentBox: this,
      sliderTheme: _sliderTheme,
      textDirection: _textDirection,
      value: _value,
      textScaleFactor: textScaleFactor,
      sizeWithOverflow: screenSize.isEmpty ? size : screenSize,
    );
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);

    // The Slider widget has its own Focus widget with semantics information,
    // and we want that semantics node to collect the semantics information here
    // so that it's all in the same node: otherwise Talkback sees that the node
    // has focusable children, and it won't focus the Slider's Focus widget
    // because it thinks the Focus widget's node doesn't have anything to say
    // (which it doesn't, but this child does). Aggregating the semantic
    // information into one node means that Talkback will recognize that it has
    // something to say and focus it when it receives keyboard focus.
    // (See https://github.com/flutter/flutter/issues/57038 for context).
    config.isSemanticBoundary = false;

    config.isEnabled = isInteractive;
    config.textDirection = textDirection;
    if (isInteractive) {
      config.onIncrease = increaseAction;
      config.onDecrease = decreaseAction;
    }

    if (semanticFormatterCallback != null) {
      config.value = semanticFormatterCallback!(_state._lerp(value));
      config.increasedValue = semanticFormatterCallback!(
          _state._lerp(clampDouble(value + _semanticActionUnit, 0.0, 1.0)));
      config.decreasedValue = semanticFormatterCallback!(
          _state._lerp(clampDouble(value - _semanticActionUnit, 0.0, 1.0)));
    } else {
      config.value = '${(value * 100).round()}%';
      config.increasedValue =
          '${(clampDouble(value + _semanticActionUnit, 0.0, 1.0) * 100).round()}%';
      config.decreasedValue =
          '${(clampDouble(value - _semanticActionUnit, 0.0, 1.0) * 100).round()}%';
    }
  }

  double get _semanticActionUnit =>
      divisions != null ? 1.0 / divisions! : _adjustmentUnit;

  void increaseAction() {
    if (isInteractive) {
      onChanged!(clampDouble(value + _semanticActionUnit, 0.0, 1.0));
    }
  }

  void decreaseAction() {
    if (isInteractive) {
      onChanged!(clampDouble(value - _semanticActionUnit, 0.0, 1.0));
    }
  }
}

class _AdjustSliderIntent extends Intent {
  const _AdjustSliderIntent({
    required this.type,
  });

  const _AdjustSliderIntent.right() : type = _SliderAdjustmentType.right;

  const _AdjustSliderIntent.left() : type = _SliderAdjustmentType.left;

  const _AdjustSliderIntent.up() : type = _SliderAdjustmentType.up;

  const _AdjustSliderIntent.down() : type = _SliderAdjustmentType.down;

  final _SliderAdjustmentType type;
}

enum _SliderAdjustmentType {
  right,
  left,
  up,
  down,
}

class _ValueIndicatorRenderObjectWidget extends LeafRenderObjectWidget {
  const _ValueIndicatorRenderObjectWidget({
    required this.state,
  });

  final _SquigglySliderState state;

  @override
  _RenderValueIndicator createRenderObject(BuildContext context) {
    return _RenderValueIndicator(
      state: state,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderValueIndicator renderObject) {
    renderObject._state = state;
  }
}

class _RenderValueIndicator extends RenderBox
    with RelayoutWhenSystemFontsChangeMixin {
  _RenderValueIndicator({
    required _SquigglySliderState state,
  }) : _state = state {
    _valueIndicatorAnimation = CurvedAnimation(
      parent: _state.valueIndicatorController,
      curve: Curves.fastOutSlowIn,
    );
  }
  late Animation<double> _valueIndicatorAnimation;
  _SquigglySliderState _state;

  @override
  bool get sizedByParent => true;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _valueIndicatorAnimation.addListener(markNeedsPaint);
    _state.positionController.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _valueIndicatorAnimation.removeListener(markNeedsPaint);
    _state.positionController.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _state.paintValueIndicator?.call(context, offset);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.smallest;
  }
}

class _SliderDefaultsM2 extends SliderThemeData {
  _SliderDefaultsM2(this.context)
      : _colors = Theme.of(context).colorScheme,
        super(trackHeight: 4.0);

  final BuildContext context;
  final ColorScheme _colors;

  @override
  Color? get activeTrackColor => _colors.primary;

  @override
  Color? get inactiveTrackColor => _colors.primary.withOpacity(0.24);

  @override
  Color? get secondaryActiveTrackColor => _colors.primary.withOpacity(0.54);

  @override
  Color? get disabledActiveTrackColor => _colors.onSurface.withOpacity(0.32);

  @override
  Color? get disabledInactiveTrackColor => _colors.onSurface.withOpacity(0.12);

  @override
  Color? get disabledSecondaryActiveTrackColor =>
      _colors.onSurface.withOpacity(0.12);

  @override
  Color? get activeTickMarkColor => _colors.onPrimary.withOpacity(0.54);

  @override
  Color? get inactiveTickMarkColor => _colors.primary.withOpacity(0.54);

  @override
  Color? get disabledActiveTickMarkColor => _colors.onPrimary.withOpacity(0.12);

  @override
  Color? get disabledInactiveTickMarkColor =>
      _colors.onSurface.withOpacity(0.12);

  @override
  Color? get thumbColor => _colors.primary;

  @override
  Color? get disabledThumbColor =>
      Color.alphaBlend(_colors.onSurface.withOpacity(.38), _colors.surface);

  @override
  Color? get overlayColor => _colors.primary.withOpacity(0.12);

  @override
  TextStyle? get valueIndicatorTextStyle =>
      Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: _colors.onPrimary,
          );

  @override
  SliderComponentShape? get valueIndicatorShape =>
      const RectangularSliderValueIndicatorShape();
}

// BEGIN GENERATED TOKEN PROPERTIES - Slider

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

// Token database version: v0_143

class _SliderDefaultsM3 extends SliderThemeData {
  _SliderDefaultsM3(this.context)
      : _colors = Theme.of(context).colorScheme,
        super(trackHeight: 4.0);

  final BuildContext context;
  final ColorScheme _colors;

  @override
  Color? get activeTrackColor => _colors.primary;

  @override
  Color? get inactiveTrackColor => _colors.surfaceVariant;

  @override
  Color? get secondaryActiveTrackColor => _colors.primary.withOpacity(0.54);

  @override
  Color? get disabledActiveTrackColor => _colors.onSurface.withOpacity(0.38);

  @override
  Color? get disabledInactiveTrackColor => _colors.onSurface.withOpacity(0.12);

  @override
  Color? get disabledSecondaryActiveTrackColor =>
      _colors.onSurface.withOpacity(0.12);

  @override
  Color? get activeTickMarkColor => _colors.onPrimary.withOpacity(0.38);

  @override
  Color? get inactiveTickMarkColor =>
      _colors.onSurfaceVariant.withOpacity(0.38);

  @override
  Color? get disabledActiveTickMarkColor => _colors.onSurface.withOpacity(0.38);

  @override
  Color? get disabledInactiveTickMarkColor =>
      _colors.onSurface.withOpacity(0.38);

  @override
  Color? get thumbColor => _colors.primary;

  @override
  Color? get disabledThumbColor =>
      Color.alphaBlend(_colors.onSurface.withOpacity(0.38), _colors.surface);

  @override
  Color? get overlayColor =>
      MaterialStateColor.resolveWith((Set<MaterialState> states) {
        if (states.contains(MaterialState.hovered)) {
          return _colors.primary.withOpacity(0.08);
        }
        if (states.contains(MaterialState.focused)) {
          return _colors.primary.withOpacity(0.12);
        }
        if (states.contains(MaterialState.dragged)) {
          return _colors.primary.withOpacity(0.12);
        }

        return Colors.transparent;
      });

  @override
  TextStyle? get valueIndicatorTextStyle =>
      Theme.of(context).textTheme.labelMedium!.copyWith(
            color: _colors.onPrimary,
          );

  @override
  SliderComponentShape? get valueIndicatorShape =>
      const DropSliderValueIndicatorShape();
}

// END GENERATED TOKEN PROPERTIES - Slider
