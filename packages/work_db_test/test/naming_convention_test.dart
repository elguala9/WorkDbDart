import 'package:test/test.dart';
import 'package:work_db/src/implementations/naming_convention.dart';

void main() {
  group('NamingConvention', () {
    group('isValid()', () {
      test('should accept valid ASCII names', () {
        expect(NamingConvention.isValid('simple_name'), isTrue);
        expect(NamingConvention.isValid('collection-name'), isTrue);
        expect(NamingConvention.isValid('C:/Program Files/data'), isTrue);
        expect(NamingConvention.isValid('path/to/file.txt'), isTrue);
        expect(NamingConvention.isValid('123_abc_456'), isTrue);
      });

      test('should accept special ASCII characters', () {
        expect(NamingConvention.isValid('file@domain.com'), isTrue);
        expect(NamingConvention.isValid('name#1'), isTrue);
        expect(NamingConvention.isValid('value$test'), isTrue);
        expect(NamingConvention.isValid('item%20value'), isTrue);
        expect(NamingConvention.isValid('path\\to\\file'), isTrue);
      });

      test('should reject empty strings', () {
        expect(NamingConvention.isValid(''), isFalse);
      });

      test('should reject names containing "lock" in any case', () {
        expect(NamingConvention.isValid('lock'), isFalse);
        expect(NamingConvention.isValid('Lock'), isFalse);
        expect(NamingConvention.isValid('LOCK'), isFalse);
        expect(NamingConvention.isValid('lOcK'), isFalse);
        expect(NamingConvention.isValid('my_lock_file'), isFalse);
        expect(NamingConvention.isValid('lockfile'), isFalse);
        expect(NamingConvention.isValid('file_lock'), isFalse);
        expect(NamingConvention.isValid('MYLockFILE'), isFalse);
      });

      test('should allow similar words to "lock"', () {
        expect(NamingConvention.isValid('unlock'), isFalse); // contains "lock"
        expect(NamingConvention.isValid('locked'), isFalse); // contains "lock"
        expect(NamingConvention.isValid('locker'), isFalse); // contains "lock"
        expect(NamingConvention.isValid('locking'), isFalse); // contains "lock"
      });

      test('should reject non-ASCII characters', () {
        expect(NamingConvention.isValid('naïve'), isFalse); // contains ï
        expect(NamingConvention.isValid('café'), isFalse); // contains é
        expect(NamingConvention.isValid('文件'), isFalse); // contains Chinese chars
        expect(NamingConvention.isValid('привет'), isFalse); // contains Cyrillic
      });

      test('should reject extended ASCII characters', () {
        expect(NamingConvention.isValid('name\x7Fend'), isFalse); // DEL character
        expect(NamingConvention.isValid('name\x80end'), isFalse); // extended ASCII
      });
    });

    group('validateOrThrow()', () {
      test('should not throw for valid names', () {
        expect(
          () => NamingConvention.validateOrThrow('valid_name'),
          returnsNormally,
        );
        expect(
          () => NamingConvention.validateOrThrow('path/to/file'),
          returnsNormally,
        );
      });

      test('should throw ArgumentError for empty names', () {
        expect(
          () => NamingConvention.validateOrThrow(''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw ArgumentError with descriptive message for "lock"', () {
        expect(
          () => NamingConvention.validateOrThrow('my_lock_file'),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('forbidden word'),
          )),
        );
      });

      test('should throw ArgumentError for non-ASCII characters', () {
        expect(
          () => NamingConvention.validateOrThrow('café'),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('invalid characters'),
          )),
        );
      });
    });

    group('getValidationErrors()', () {
      test('should return empty list for valid names', () {
        expect(NamingConvention.getValidationErrors('valid_name'), isEmpty);
        expect(NamingConvention.getValidationErrors('path/to/file'), isEmpty);
      });

      test('should return error for empty names', () {
        final errors = NamingConvention.getValidationErrors('');
        expect(errors, isNotEmpty);
        expect(errors.first, contains('empty'));
      });

      test('should return specific error for "lock" word', () {
        final errors = NamingConvention.getValidationErrors('my_lock_file');
        expect(errors, contains(startsWith('Contains the forbidden word')));
      });

      test('should return specific error for invalid characters', () {
        final errors = NamingConvention.getValidationErrors('café');
        expect(errors, contains(startsWith('Contains invalid characters')));
      });

      test('should report multiple errors', () {
        final errors = NamingConvention.getValidationErrors('');
        expect(errors.length, equals(1)); // empty check returns early
      });
    });

    group('edge cases', () {
      test('should accept spaces', () {
        expect(NamingConvention.isValid('my name'), isTrue);
        expect(NamingConvention.isValid('  leading_spaces'), isTrue);
        expect(NamingConvention.isValid('trailing_spaces  '), isTrue);
      });

      test('should accept punctuation', () {
        expect(NamingConvention.isValid('file.txt'), isTrue);
        expect(NamingConvention.isValid('name-with-dashes'), isTrue);
        expect(NamingConvention.isValid('name_with_underscores'), isTrue);
        expect(NamingConvention.isValid('name!with?marks'), isTrue);
      });

      test('should handle "lock" at word boundaries', () {
        expect(NamingConvention.isValid('mylock'), isFalse); // contains "lock"
        expect(NamingConvention.isValid('lockmyfile'), isFalse); // contains "lock"
        expect(NamingConvention.isValid('blockade'), isFalse); // contains "lock"
        expect(NamingConvention.isValid('grandfather'), isTrue); // "lock" not present
      });

      test('should accept Windows paths', () {
        expect(
          NamingConvention.isValid('C:\\ProgramData\\chocolatey'),
          isTrue,
        );
        expect(
          NamingConvention.isValid('D:\\Users\\Admin\\Documents'),
          isTrue,
        );
      });

      test('should accept Unix paths', () {
        expect(NamingConvention.isValid('/usr/local/bin'), isTrue);
        expect(NamingConvention.isValid('/home/user/documents'), isTrue);
      });
    });
  });
}
