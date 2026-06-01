import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// This imports your FitPostureApp class
import 'package:fit_posture_app/main.dart';

void main() {
  testWidgets('App load smoke test', (WidgetTester tester) async {
    // 1. Build our app and trigger a frame.
    // This matches the class name in your main.dart
    await tester.pumpWidget(const FitPostureApp());

    // 2. Verify that the app starts by checking if the MaterialApp exists.
    // This replaces the "0" and "1" counter logic which was causing errors.
    expect(find.byType(MaterialApp), findsOneWidget);

    // 3. Since your app starts with a SplashScreen, we check if the app 
    // is running without crashing.
    debugPrint("App started successfully in test mode");
  });
}