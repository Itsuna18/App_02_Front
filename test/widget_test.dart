import 'package:flutter_test/flutter_test.dart';
import 'package:front_medicity/main.dart';

void main() {
  testWidgets('Carga la app correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Medicity Distribuida'), findsWidgets);
  });
}
