import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';

void main() {
  testWidgets('BDPHS App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BDPHSApp());
  });
}