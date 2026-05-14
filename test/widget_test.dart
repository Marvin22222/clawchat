import 'package:flutter_test/flutter_test.dart';

import 'package:clawchat/app.dart';

void main() {
  testWidgets('ClawChat app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ClawChatApp());
    await tester.pump();
    expect(find.byType(ClawChatApp), findsOneWidget);
  });
}
