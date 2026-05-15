import 'package:flutter_test/flutter_test.dart';
import 'package:borrow_tracker/main.dart';

void main() {
  testWidgets('App loads and shows auth screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BorrowTrackerApp());
    expect(find.text('Borrow Tracker'), findsOneWidget);
  });
}