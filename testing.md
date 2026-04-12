# Dart Testing Standards

Dart and Flutter-specific testing rules. These extend the common [testing.md](file:///Users/abhishekkulkarni/.gemini/rules/testing.md).

## Coverage Requirement: 95%+

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

Coverage below 95% on business logic is a **blocking** issue. All state transitions must have tests: loading → success, loading → error, retry, empty.

## Test Framework

- **flutter_test** / **dart:test** — built-in test runner.
- **mockito** (with `@GenerateMocks`) or **mocktail** (no codegen) for mocking.
- **bloc_test** for BLoC/Cubit unit tests.
- **fake_async** for controlling time in unit tests.
- **integration_test** for end-to-end device tests.

## Test Types

| Type | Tool | Location | When to Write |
|------|------|----------|---------------|
| Unit | `dart:test` | `test/unit/` | All domain logic, state managers, repositories |
| Widget | `flutter_test` | `test/widget/` | All widgets with meaningful behavior |
| Golden | `flutter_test` | `test/golden/` | Design-critical UI components |
| Integration | `integration_test` | `integration_test/` | Critical user flows on real device/emulator |

## Test Organization

```
test/
├── unit/
│   ├── domain/
│   │   └── usecases/
│   └── data/
│       └── repositories/
├── widget/
│   └── presentation/
│       └── pages/
└── golden/
    └── widgets/

integration_test/
└── flows/
    ├── login_flow_test.dart
    └── checkout_flow_test.dart
```

## BLoC Testing

```dart
group('CartBloc', () {
  late CartBloc bloc;
  late MockCartRepository repository;

  setUp(() {
    repository = MockCartRepository();
    bloc = CartBloc(repository);
  });

  tearDown(() => bloc.close());

  blocTest<CartBloc, CartState>(
    'emits updated items when CartItemAdded',
    build: () => bloc,
    act: (b) => b.add(CartItemAdded(testItem)),
    expect: () => [CartState(items: [testItem])],
  );

  blocTest<CartBloc, CartState>(
    'emits empty cart when CartCleared',
    seed: () => CartState(items: [testItem]),
    build: () => bloc,
    act: (b) => b.add(CartCleared()),
    expect: () => [const CartState()],
  );
});
```

## Riverpod Testing

```dart
test('usersProvider loads users from repository', () async {
  final container = ProviderContainer(
    overrides: [
      userRepositoryProvider.overrideWithValue(FakeUserRepository()),
    ],
  );
  addTearDown(container.dispose);

  final result = await container.read(usersProvider.future);
  expect(result, isNotEmpty);
});
```

## Widget Testing

```dart
testWidgets('CartPage shows item count badge', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        cartNotifierProvider.overrideWith(() => FakeCartNotifier([testItem])),
      ],
      child: const MaterialApp(home: CartPage()),
    ),
  );

  await tester.pump();
  expect(find.text('1'), findsOneWidget);
  expect(find.byType(CartItemTile), findsOneWidget);
});

testWidgets('shows empty state when cart is empty', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        cartNotifierProvider.overrideWith(() => FakeCartNotifier([])),
      ],
      child: const MaterialApp(home: CartPage()),
    ),
  );

  await tester.pump();
  expect(find.text('Your cart is empty'), findsOneWidget);
});
```

## Fakes Over Mocks

Prefer hand-written fakes for complex dependencies — they're easier to debug and don't require codegen:

```dart
class FakeUserRepository implements UserRepository {
  final _users = <String, User>{};
  Object? fetchError;

  @override
  Future<User?> getById(String id) async {
    if (fetchError != null) throw fetchError!;
    return _users[id];
  }

  @override
  Future<List<User>> getAll() async {
    if (fetchError != null) throw fetchError!;
    return _users.values.toList();
  }

  @override
  Stream<List<User>> watchAll() => Stream.value(_users.values.toList());

  @override
  Future<void> save(User user) async => _users[user.id] = user;

  @override
  Future<void> delete(String id) async => _users.remove(id);

  void addUser(User user) => _users[user.id] = user;
}
```

## Async Testing

```dart
// Use fake_async for controlling timers and Futures
test('debounce triggers after 300ms', () {
  fakeAsync((async) {
    final debouncer = Debouncer(delay: const Duration(milliseconds: 300));
    var callCount = 0;
    debouncer.run(() => callCount++);
    expect(callCount, 0);
    async.elapse(const Duration(milliseconds: 200));
    expect(callCount, 0);
    async.elapse(const Duration(milliseconds: 200));
    expect(callCount, 1);
  });
});
```

## Golden Tests

```dart
testWidgets('UserCard golden test', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: UserCard(user: testUser)),
  );

  await expectLater(
    find.byType(UserCard),
    matchesGoldenFile('goldens/user_card.png'),
  );
});
```

Run `flutter test --update-goldens` when intentional visual changes are made.

## HTTP Mocking

```dart
// Use MockClient from package:http
final mockClient = MockClient((request) async {
  if (request.url.path == '/users') {
    return http.Response('{"users": []}', 200);
  }
  return http.Response('Not Found', 404);
});
```

## Test Naming

Use descriptive, behavior-focused names:

```dart
test('returns null when user does not exist', () { ... });
test('throws NotFoundException when id is empty string', () { ... });
testWidgets('disables submit button while form is invalid', (tester) async { ... });
```

## Platform-Specific Testing

- Use `TestDefaultBinaryMessengerBinding` for testing platform channels.
- Mock platform plugins with `setMockMethodCallHandler`.
- Test both Android and iOS code paths when behavior differs.
- Use `debugDefaultTargetPlatformOverride` to simulate platforms in widget tests.

## Test Isolation

- Use `setUp()` / `tearDown()` for every test group.
- Close all BLoCs, StreamControllers, and ProviderContainers in tearDown.
- Never share mutable state between tests.
- Use `addTearDown()` for resources created mid-test.

## Anti-Patterns

| Anti-Pattern | Do This Instead |
|-------------|-----------------|
| `await tester.pumpAndSettle()` with no timeout | Add a timeout: `pumpAndSettle(timeout: Duration(seconds: 5))` |
| Testing widget internals via `State` | Test via user-visible behavior (find.text, find.byType) |
| Skipping `tearDown` for BLoCs | Always `bloc.close()` in tearDown |
| Using `print()` for debugging tests | Use `debugPrint()` or structured logging |
| Hardcoded test data scattered everywhere | Create a `test/fixtures/` with shared test data factories |
