import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:interactive_reading_app/app/app.dart';
import 'package:interactive_reading_app/app/di/injection.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.init(force: true);
  });

  testWidgets('Library page shows empty state', (tester) async {
    await tester.pumpWidget(const InteractiveReadingApp());
    await tester.pumpAndSettle();

    expect(find.text('Библиотека'), findsOneWidget);
    expect(find.text('Библиотека пуста'), findsOneWidget);
    expect(find.text('Открыть EPUB'), findsOneWidget);
  });
}
