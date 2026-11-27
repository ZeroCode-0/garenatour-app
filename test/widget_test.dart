import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/theme/app_theme.dart';

void main() {
  testWidgets('app theme builds', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(body: Center(child: Text('Garena Tour'))),
        ),
      ),
    );
    expect(find.text('Garena Tour'), findsOneWidget);
  });
}
