import 'package:flutter_test/flutter_test.dart';
import 'package:hydrate/main.dart';

void main() {
  testWidgets('shows login screen on app start', (tester) async {
    await tester.pumpWidget(const HydrateApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });
}
