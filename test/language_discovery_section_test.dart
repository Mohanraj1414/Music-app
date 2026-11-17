import 'package:Bloomee/screens/widgets/language_discovery_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  for (final (id, expectedQuery) in [
    ('tamil', 'Tamil songs'),
    ('english', 'English songs'),
    ('kannada', 'Kannada songs'),
    ('hindi', 'Hindi songs'),
  ]) {
    testWidgets('$id discovery card opens a language search', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(
              body: SingleChildScrollView(
                child: LanguageDiscoverySection(),
              ),
            ),
          ),
          GoRoute(
            path: '/Search',
            builder: (_, state) => Scaffold(
              body: Text(state.uri.queryParameters['query'] ?? ''),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.binding.setSurfaceSize(const Size(1220, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final card = find.byKey(ValueKey('language-$id'));
      expect(card, findsOneWidget);
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pumpAndSettle();

      expect(find.text(expectedQuery), findsOneWidget);
    });
  }
}
