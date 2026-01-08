# Testing Guide

## Overview

This guide explains how to set up and run tests for the Inglenook Grocery apps.

---

## Test Structure

Each app has a `test/` directory with unit tests:

```
grocery_user/
  test/
    helpers/
      input_sanitizer_test.dart
      validators_test.dart
    services/
      error_logger_test.dart
    widget_test.dart
```

---

## Running Tests

### Run All Tests

```bash
cd "Groccery App/grocery_user"
flutter test
```

### Run Specific Test File

```bash
flutter test test/helpers/input_sanitizer_test.dart
```

### Run Tests with Coverage

```bash
flutter test --coverage

# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html

# Open in browser
open coverage/html/index.html
```

---

## Writing Tests

### Unit Test Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery/helpers/input_sanitizer.dart';

void main() {
  group('InputSanitizer', () {
    test('sanitizes email correctly', () {
      final result = InputSanitizer.sanitizeEmail('Test@Example.COM');
      expect(result, 'test@example.com');
    });

    test('rejects invalid email', () {
      final result = InputSanitizer.sanitizeEmail('invalid');
      expect(result, null);
    });
  });
}
```

### Widget Test Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery/ui/home/home.dart';

void main() {
  testWidgets('Home page displays title', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: HomePage()));

    expect(find.text('Inglenook'), findsOneWidget);
  });
}
```

### Integration Test Example

Create `integration_test/app_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:grocery/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete user flow', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Find and tap login button
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // Enter credentials
    await tester.enterText(find.byKey(Key('email')), 'test@example.com');
    await tester.enterText(find.byKey(Key('password')), 'Test1234!');

    // Submit
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    // Verify navigation to home
    expect(find.text('Home'), findsOneWidget);
  });
}
```

Run integration tests:

```bash
flutter test integration_test/app_test.dart
```

---

## Test Coverage Goals

- **Unit Tests**: 80%+ coverage
- **Widget Tests**: 70%+ coverage
- **Integration Tests**: Key user flows

---

## Firebase Testing

### Using Firebase Emulators

```bash
# Install emulators
firebase init emulators

# Select: Firestore, Authentication, Functions

# Start emulators
firebase emulators:start

# In your app, connect to emulators
# lib/main.dart:
if (kDebugMode) {
  await FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
}
```

### Security Rules Testing

Create `firestore.test.js`:

```javascript
const firebase = require('@firebase/testing');
const fs = require('fs');

const PROJECT_ID = 'inglenook-test';

function getFirestore(auth) {
  return firebase
    .initializeTestApp({ projectId: PROJECT_ID, auth })
    .firestore();
}

describe('Firestore Security Rules', () => {
  beforeEach(async () => {
    await firebase.clearFirestoreData({ projectId: PROJECT_ID });
  });

  after(async () => {
    await firebase.clearFirestoreData({ projectId: PROJECT_ID });
  });

  it('denies unauthenticated users from reading products', async () => {
    const db = getFirestore(null);
    const products = db.collection('products');

    await firebase.assertSucceeds(products.get());
  });

  it('allows authenticated users to create orders', async () => {
    const db = getFirestore({ uid: 'user123' });
    const orders = db.collection('orders');

    await firebase.assertSucceeds(
      orders.add({
        userId: 'user123',
        items: [],
        total: 100,
      })
    );
  });

  it('denies users from accessing other users orders', async () => {
    const db = getFirestore({ uid: 'user123' });
    const orders = db.collection('orders');

    await firebase.assertFails(
      orders.doc('other-user-order').get()
    );
  });
});
```

Run:

```bash
npm test
```

---

## CI/CD Testing

### GitHub Actions

Create `.github/workflows/test.yml`:

```yaml
name: Run Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'

    - name: Install dependencies
      run: |
        cd "Groccery App/grocery_user"
        flutter pub get

    - name: Run tests
      run: |
        cd "Groccery App/grocery_user"
        flutter test --coverage

    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        files: ./Groccery App/grocery_user/coverage/lcov.info
```

---

## Mocking

### Mocking Firebase

```dart
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUserCredential extends Mock implements UserCredential {}

void main() {
  late MockFirebaseAuth mockAuth;

  setUp(() {
    mockAuth = MockFirebaseAuth();
  });

  test('signs in user', () async {
    final mockCredential = MockUserCredential();

    when(mockAuth.signInWithEmailAndPassword(
      email: anyNamed('email'),
      password: anyNamed('password'),
    )).thenAnswer((_) async => mockCredential);

    final result = await mockAuth.signInWithEmailAndPassword(
      email: 'test@example.com',
      password: 'password',
    );

    expect(result, mockCredential);
    verify(mockAuth.signInWithEmailAndPassword(
      email: 'test@example.com',
      password: 'password',
    )).called(1);
  });
}
```

---

## Test Data

Create test fixtures in `test/fixtures/`:

```dart
// test/fixtures/product_fixture.dart
import 'package:grocery/models/product.dart';

class ProductFixture {
  static Product get sampleProduct => Product(
    id: 'prod-123',
    title: 'Test Product',
    price: 9.99,
    categoryId: 'cat-1',
    inStock: true,
  );

  static List<Product> get productList => [
    sampleProduct,
    Product(id: 'prod-456', title: 'Another Product', price: 19.99),
  ];
}
```

Use in tests:

```dart
import 'fixtures/product_fixture.dart';

test('adds product to cart', () {
  final product = ProductFixture.sampleProduct;
  // ... test code
});
```

---

## Performance Testing

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('search performs in under 100ms', () {
    final stopwatch = Stopwatch()..start();

    // Perform search
    final results = searchProducts('query');

    stopwatch.stop();

    expect(stopwatch.elapsedMilliseconds, lessThan(100));
  });
}
```

---

## Troubleshooting

### Test fails with "No Firebase App"

Mock Firebase or use emulators:

```dart
setUp(() async {
  await Firebase.initializeApp();
});
```

### Widget test fails with "MediaQuery not found"

Wrap in MaterialApp:

```dart
await tester.pumpWidget(
  MaterialApp(
    home: YourWidget(),
  ),
);
```

### Coverage not generated

Make sure `lcov` is installed:

```bash
# macOS
brew install lcov

# Linux
sudo apt-get install lcov
```

---

## Best Practices

1. **Test Naming**: Use descriptive names
   - ✅ `test('rejects invalid email')`
   - ❌ `test('test1')`

2. **Arrange-Act-Assert**: Structure tests clearly
   ```dart
   test('description', () {
     // Arrange
     final input = 'test';

     // Act
     final result = function(input);

     // Assert
     expect(result, expected);
   });
   ```

3. **One Assertion Per Test**: Keep tests focused

4. **Use Groups**: Organize related tests
   ```dart
   group('Authentication', () {
     group('Login', () {
       test('succeeds with valid credentials', () {});
       test('fails with invalid credentials', () {});
     });
   });
   ```

5. **Clean Up**: Use `tearDown` to clean up resources

6. **Test Edge Cases**: Empty strings, null, extremes

---

## Resources

- [Flutter Testing Documentation](https://flutter.dev/docs/testing)
- [Firebase Emulator Documentation](https://firebase.google.com/docs/emulator-suite)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Integration Testing](https://flutter.dev/docs/testing/integration-tests)

---

Last Updated: 2026-01-08
