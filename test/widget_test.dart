// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yugioh_scanner/main.dart';

void main() {
  test('MyApp class is defined', () {
    // Verify that MyApp is now a valid class
    expect(MyApp, isA<Type>());
    expect(MyApp(), isA<StatelessWidget>());

    // This test verifies that the original error "The name 'MyApp' isn't a class" is fixed
  });
}
