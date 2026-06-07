import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Flutter test environment smoke test', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Text('Food Foundation'),
          ),
        ),
      ),
    );

    expect(find.text('Food Foundation'), findsOneWidget);
  });
}