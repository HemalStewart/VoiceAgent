import 'package:flutter_test/flutter_test.dart';
import 'package:englishmind_mobile/main.dart';

void main() {
  testWidgets('EnglishMindApp smoke test and navigation load', (WidgetTester tester) async {
    await tester.pumpWidget(const EnglishMindApp());
    expect(find.byType(EnglishMindApp), findsOneWidget);
  });
}
