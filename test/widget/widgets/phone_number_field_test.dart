import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/widgets/phone_number_field.dart';

void main() {
  late TextEditingController code;
  late TextEditingController number;
  late GlobalKey<FormState> formKey;

  setUp(() {
    code = TextEditingController(text: '+1');
    number = TextEditingController();
    formKey = GlobalKey<FormState>();
  });

  tearDown(() {
    code.dispose();
    number.dispose();
  });

  Widget wrap({bool required = true}) => MaterialApp(
    home: Scaffold(
      body: Form(
        key: formKey,
        child: PhoneNumberField(
          codeController: code,
          numberController: number,
          label: 'Phone',
          required: required,
          requiredMessage: 'Phone is required',
          invalidMessage: 'Enter a valid phone',
          codeKey: const Key('code'),
          numberKey: const Key('number'),
        ),
      ),
    ),
  );

  Future<bool> validate(WidgetTester tester) async {
    final valid = formKey.currentState!.validate();
    await tester.pump();
    return valid;
  }

  testWidgets('shows the prefilled code next to the phone number', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());

    expect(code.text, '+1');
    expect(find.byKey(const Key('code')), findsOneWidget);
    expect(find.text('Code'), findsOneWidget);
    expect(find.text('Phone'), findsOneWidget);
  });

  testWidgets('requires a number when required', (tester) async {
    await tester.pumpWidget(wrap());

    expect(await validate(tester), isFalse);
    expect(find.text('Phone is required'), findsOneWidget);
  });

  testWidgets('allows a blank number when optional', (tester) async {
    await tester.pumpWidget(wrap(required: false));

    expect(await validate(tester), isTrue);
  });

  testWidgets('still checks an optional number once it is entered', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(required: false));
    await tester.enterText(find.byKey(const Key('number')), '12345');

    expect(await validate(tester), isFalse);
    expect(find.text('Enter a valid phone'), findsOneWidget);
  });

  testWidgets('needs ten digits for most countries', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.enterText(find.byKey(const Key('number')), '123456789');
    expect(await validate(tester), isFalse);

    await tester.enterText(find.byKey(const Key('number')), '1234567890');
    expect(await validate(tester), isTrue);
  });

  testWidgets('needs fewer digits for countries that use fewer', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    code.text = '+65';
    await tester.enterText(find.byKey(const Key('number')), '91234567');
    expect(await validate(tester), isTrue);

    code.text = '+971';
    await tester.enterText(find.byKey(const Key('number')), '12345678');
    expect(await validate(tester), isFalse);
    await tester.enterText(find.byKey(const Key('number')), '501234567');
    expect(await validate(tester), isTrue);
  });

  testWidgets('counts digits only, ignoring spaces and dashes', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.enterText(find.byKey(const Key('number')), '585-123 4567');

    expect(await validate(tester), isTrue);
  });

  testWidgets('rejects a country code without a plus or with too many '
      'digits', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.enterText(find.byKey(const Key('number')), '1234567890');

    code.text = '91';
    expect(await validate(tester), isFalse);
    code.text = '+12345';
    expect(await validate(tester), isFalse);
    code.text = '+91';
    expect(await validate(tester), isTrue);
  });

  testWidgets('limits the number to 30 characters', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.enterText(find.byKey(const Key('number')), '1' * 40);

    expect(number.text.length, 30);
  });
}
