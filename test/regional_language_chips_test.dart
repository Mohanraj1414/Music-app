import 'package:Bloomee/screens/widgets/regional_language_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('regional search chips emit matching provider search queries',
      (tester) async {
    final searches = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RegionalLanguageChips(
            onSelected: searches.add,
          ),
        ),
      ),
    );

    for (final query in [
      'Tamil songs',
      'English songs',
      'Kannada songs',
      'Hindi songs',
    ]) {
      final chip = find.byKey(ValueKey('search-' + query));
      expect(chip, findsOneWidget);
      await tester.tap(chip);
      await tester.pump();
    }

    expect(searches, ['Tamil songs', 'English songs', 'Kannada songs', 'Hindi songs']);
  });
}
