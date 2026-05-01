// Basic widget test for SafeRide app
import 'package:flutter_test/flutter_test.dart';
import 'package:pex_2026/main.dart';

void main() {
  testWidgets('SafeRide app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    
    // Verify that the app starts (AuthCheck widget)
    // The app should show loading indicator initially
    await tester.pump(const Duration(milliseconds: 100));
    
    // Just verify the app builds without crashing
    expect(find.byType(MyApp), findsOneWidget);
  });
}
