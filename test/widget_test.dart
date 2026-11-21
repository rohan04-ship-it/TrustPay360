
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:hackathon_app/main.dart' as trustpay;

void main() {
  testWidgets('TrustPay 360 home screen opens', (tester) async {
    await tester.pumpWidget(const trustpay.TrustPayApp());

    expect(find.text('TrustPay 360'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.byIcon(Icons.send), findsOneWidget);
  });
}
