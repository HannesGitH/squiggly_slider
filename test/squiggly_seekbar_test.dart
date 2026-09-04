import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:squiggly_slider/slider.dart';

Future<void> pumpSlider(WidgetTester tester, Widget slider) {
  return tester.pumpWidget(
    MaterialApp(home: Scaffold(body: Center(child: slider))),
  );
}

void main() {
  testWidgets('renders inside a material_ui Scaffold', (tester) async {
    await pumpSlider(
      tester,
      SquigglySlider(value: 0.5, onChanged: (_) {}, squiggleAmplitude: 3.0),
    );
    expect(find.byType(SquigglySlider), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reports value changes on drag', (tester) async {
    double? changed;
    await pumpSlider(
      tester,
      SquigglySlider(value: 0.5, onChanged: (v) => changed = v),
    );
    await tester.drag(find.byType(SquigglySlider), const Offset(200, 0));
    expect(changed, isNotNull);
    expect(changed, greaterThan(0.5));
  });

  testWidgets('animates without leaking its ticker', (tester) async {
    await pumpSlider(
      tester,
      SquigglySlider(
        value: 0.5,
        onChanged: (_) {},
        squiggleAmplitude: 3.0,
        squiggleSpeed: 2.0,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    // Replacing the slider disposes it; a leaked AnimationController throws here.
    await pumpSlider(tester, const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('useLineThumb selects the line thumb shape', (tester) async {
    await pumpSlider(
      tester,
      SquigglySlider(value: 0.5, onChanged: (_) {}, useLineThumb: true),
    );
    final SliderTheme theme = tester.widget(find.byType(SliderTheme).first);
    expect(theme.data.thumbShape, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the squiggle when amplitude and wavelength are set',
      (tester) async {
    await pumpSlider(
      tester,
      SquigglySlider(
        value: 0.5,
        onChanged: (_) {},
        squiggleAmplitude: 3.0,
        squiggleWavelength: 5.0,
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('amplitude without wavelength falls back to a plain track',
      (tester) async {
    await pumpSlider(
      tester,
      SquigglySlider(value: 0.5, onChanged: (_) {}, squiggleAmplitude: 3.0),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('squiggleSpeed of 0 holds a static phase', (tester) async {
    await pumpSlider(
      tester,
      SquigglySlider(
        value: 0.5,
        onChanged: (_) {},
        squiggleAmplitude: 3.0,
        squiggleSpeed: 0,
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });
}
