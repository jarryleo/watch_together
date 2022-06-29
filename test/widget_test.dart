// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:async';

import 'package:dlna_dart/dlna.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:watch_together/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });


  test("dlna test", () async {
    final searcher = search();
    final m = await searcher.start();
    Timer.periodic(const Duration(seconds: 3), (timer) {
      m.deviceList.forEach((key, value) async {
        print(key);
        if (value.info.friendlyName.contains('Wireless')) return;
        print(value.info.friendlyName);
        // final text = await value.position();
        // final r = await value.seekByCurrent(text, 10);
        // print(r);
      });
    });

    // close the server,the closed server can be start by call searcher.start()
    Timer(const Duration(seconds: 30), () {
      searcher.stop();
      print('server closed');
    });
  });
}
