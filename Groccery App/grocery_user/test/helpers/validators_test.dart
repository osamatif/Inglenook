import 'package:flutter_test/flutter_test.dart';
import 'package:grocery/helpers/validators.dart';

void main() {
  group('Validators', () {
    group('email', () {
      test('accepts valid email', () {
        expect(Validators.email('test@example.com'), true);
      });

      test('rejects invalid email', () {
        expect(Validators.email('invalid'), false);
        expect(Validators.email('test@'), false);
        expect(Validators.email('@example.com'), false);
      });
    });

    group('password', () {
      test('accepts strong password', () {
        expect(Validators.password('Test1234!'), true);
      });

      test('rejects weak password without uppercase', () {
        expect(Validators.password('test1234!'), false);
      });

      test('rejects weak password without lowercase', () {
        expect(Validators.password('TEST1234!'), false);
      });

      test('rejects weak password without number', () {
        expect(Validators.password('TestTest!'), false);
      });

      test('rejects weak password without special char', () {
        expect(Validators.password('Test1234'), false);
      });

      test('rejects short password', () {
        expect(Validators.password('Test1!'), false);
      });
    });
  });
}
