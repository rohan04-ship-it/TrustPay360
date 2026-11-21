import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_app/main.dart';

void main() {
  testWidgets('TrustPay 360 home screen opens', (tester) async {
    await tester.pumpWidget(const TrustPayApp());

    expect(find.text('TrustPay 360'), findsNWidgets(2));
    expect(find.text('Quick Actions'), findsOneWidget);
  });
}
