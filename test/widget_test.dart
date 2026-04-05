import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:glyph/main.dart';

void main() {
  testWidgets('App launches with canvas screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GlyphApp()));
    await tester.pump();

    // Should show the font picker button and export button
    expect(find.text('Select Font'), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);
    // Should show placeholder text
    expect(find.text('Type something'), findsOneWidget);
  });
}
