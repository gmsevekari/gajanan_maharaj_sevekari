import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_loading_indicator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FestivalProvider festivalProvider;

  setUp(() {
    festivalProvider = FestivalProvider();
  });

  Widget createIndicatorWidget({double size = 36.0, Color? color}) {
    return ChangeNotifierProvider<FestivalProvider>.value(
      value: festivalProvider,
      child: MaterialApp(
        home: Scaffold(
          body: ThemedLoadingIndicator(size: size, color: color),
        ),
      ),
    );
  }

  group('ThemedLoadingIndicator Widget Tests', () {
    testWidgets('renders standard CircularProgressIndicator by default', (WidgetTester tester) async {
      await tester.pumpWidget(createIndicatorWidget(size: 48.0, color: Colors.amber));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
