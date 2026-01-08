import 'package:flutter_test/flutter_test.dart';
import 'package:grocery/helpers/input_sanitizer.dart';

void main() {
  group('InputSanitizer', () {
    group('sanitize', () {
      test('removes null bytes', () {
        expect(InputSanitizer.sanitize('hello\x00world'), 'helloworld');
      });

      test('trims whitespace', () {
        expect(InputSanitizer.sanitize('  hello  '), 'hello');
      });

      test('removes control characters', () {
        expect(InputSanitizer.sanitize('hello\x01world'), 'helloworld');
      });
    });

    group('sanitizeEmail', () {
      test('accepts valid email', () {
        expect(
          InputSanitizer.sanitizeEmail('user@example.com'),
          'user@example.com',
        );
      });

      test('converts to lowercase', () {
        expect(
          InputSanitizer.sanitizeEmail('User@Example.COM'),
          'user@example.com',
        );
      });

      test('rejects invalid email', () {
        expect(InputSanitizer.sanitizeEmail('notanemail'), null);
        expect(InputSanitizer.sanitizeEmail('user@'), null);
        expect(InputSanitizer.sanitizeEmail('@example.com'), null);
      });

      test('rejects email with consecutive dots', () {
        expect(InputSanitizer.sanitizeEmail('user..name@example.com'), null);
      });
    });

    group('sanitizeName', () {
      test('allows letters and spaces', () {
        expect(
          InputSanitizer.sanitizeName('John Doe'),
          'John Doe',
        );
      });

      test('removes numbers and special characters', () {
        expect(
          InputSanitizer.sanitizeName('John123!@#'),
          'John',
        );
      });

      test('allows hyphens and apostrophes', () {
        expect(
          InputSanitizer.sanitizeName("Mary-Jane O'Brien"),
          "Mary-Jane O'Brien",
        );
      });
    });

    group('validatePrice', () {
      test('accepts valid price', () {
        expect(InputSanitizer.validatePrice('29.99'), 29.99);
      });

      test('rounds to 2 decimal places', () {
        expect(InputSanitizer.validatePrice('29.999'), 30.00);
      });

      test('rejects negative price', () {
        expect(InputSanitizer.validatePrice('-10'), null);
      });

      test('rejects price over limit', () {
        expect(InputSanitizer.validatePrice('2000000'), null);
      });
    });

    group('validateQuantity', () {
      test('accepts valid quantity', () {
        expect(InputSanitizer.validateQuantity('5'), 5);
      });

      test('rejects zero', () {
        expect(InputSanitizer.validateQuantity('0'), null);
      });

      test('rejects negative', () {
        expect(InputSanitizer.validateQuantity('-1'), null);
      });

      test('rejects decimal', () {
        expect(InputSanitizer.validateQuantity('2.5'), null);
      });

      test('rejects over limit', () {
        expect(InputSanitizer.validateQuantity('20000'), null);
      });
    });

    group('containsSqlInjection', () {
      test('detects SELECT statement', () {
        expect(InputSanitizer.containsSqlInjection('SELECT * FROM users'), true);
      });

      test('detects DROP statement', () {
        expect(InputSanitizer.containsSqlInjection('DROP TABLE users'), true);
      });

      test('detects SQL comments', () {
        expect(InputSanitizer.containsSqlInjection('test --'), true);
      });

      test('allows normal text', () {
        expect(InputSanitizer.containsSqlInjection('hello world'), false);
      });
    });

    group('containsXss', () {
      test('detects script tag', () {
        expect(
          InputSanitizer.containsXss('<script>alert("xss")</script>'),
          true,
        );
      });

      test('detects event handlers', () {
        expect(
          InputSanitizer.containsXss('<img onerror="alert()">'),
          true,
        );
      });

      test('detects javascript protocol', () {
        expect(
          InputSanitizer.containsXss('javascript:alert()'),
          true,
        );
      });

      test('allows normal HTML entities', () {
        expect(InputSanitizer.containsXss('hello &amp; world'), false);
      });
    });

    group('sanitizeSearchQuery', () {
      test('accepts valid query', () {
        expect(
          InputSanitizer.sanitizeSearchQuery('search term'),
          'search term',
        );
      });

      test('rejects query with SQL injection', () {
        expect(
          InputSanitizer.sanitizeSearchQuery('search DROP TABLE'),
          null,
        );
      });

      test('rejects query with XSS', () {
        expect(
          InputSanitizer.sanitizeSearchQuery('<script>alert()</script>'),
          null,
        );
      });

      test('removes special regex characters', () {
        expect(
          InputSanitizer.sanitizeSearchQuery('test[.*]query'),
          'testquery',
        );
      });
    });

    group('maskSensitive', () {
      test('masks credit card number', () {
        expect(
          InputSanitizer.maskSensitive('1234567890123456'),
          '************3456',
        );
      });

      test('masks short string', () {
        expect(InputSanitizer.maskSensitive('abc'), '***');
      });
    });

    group('isValidUrl', () {
      test('accepts valid http URL', () {
        expect(InputSanitizer.isValidUrl('http://example.com'), true);
      });

      test('accepts valid https URL', () {
        expect(InputSanitizer.isValidUrl('https://example.com'), true);
      });

      test('rejects non-http(s) URL', () {
        expect(InputSanitizer.isValidUrl('ftp://example.com'), false);
      });

      test('rejects invalid URL', () {
        expect(InputSanitizer.isValidUrl('not a url'), false);
      });
    });
  });
}
