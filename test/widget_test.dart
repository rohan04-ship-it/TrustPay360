
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hackathon_app/main.dart';

void main() {
  testWidgets('TrustPay 360 home screen opens', (tester) async {
    await tester.pumpWidget(const TrustPayApp());

    expect(find.text('TrustPay 360'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.byIcon(Icons.send), findsOneWidget);
  });
}
