import 'package:flutter_test/flutter_test.dart';
import 'package:all_news/main.dart';

void main() {
  testWidgets('News app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ArabicNewsApp());
    expect(find.text('أخبار العرب'), findsOneWidget);
  });
}
