import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/core/errors/app_exception.dart';
import 'package:pitmate/core/utils/result.dart';

void main() {
  group('Result<T> pattern tests', () {
    test('Success stores data and provides getters', () {
      const result = Result.success('PitMate M1');

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.dataOrNull, 'PitMate M1');
      expect(result.exceptionOrNull, isNull);

      final val = result.when(
        success: (data) => 'Got: $data',
        failure: (e) => 'Failed: ${e.message}',
      );
      expect(val, 'Got: PitMate M1');
    });

    test('Failure stores AppException and provides getters', () {
      const exception = AuthException('Invalid login', code: '401');
      const result = Result<String>.failure(exception);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.dataOrNull, isNull);
      expect(result.exceptionOrNull, exception);

      final val = result.when(
        success: (data) => 'Got: $data',
        failure: (e) => 'Failed: ${e.message}',
      );
      expect(val, 'Failed: Invalid login');
    });

    test('map transforms success and forwards failure', () {
      const successResult = Result.success(42);
      final mappedSuccess = successResult.map((n) => n * 2);
      expect(mappedSuccess.dataOrNull, 84);

      const failResult = Result<int>.failure(AuthException('err'));
      final mappedFailure = failResult.map((n) => n * 2);
      expect(mappedFailure.isFailure, isTrue);
    });

    test('equality works for Success and Failure', () {
      expect(const Result.success('test'), equals(const Result.success('test')));
      expect(
        const Result<int>.failure(ValidationException('bad')),
        equals(const Result<int>.failure(ValidationException('bad'))),
      );
    });
  });

  group('AppException subclasses tests', () {
    test('all subclasses inherit from AppException and format message', () {
      const auth = AuthException('Auth failed', code: 'invalid_grant');
      const val = ValidationException('Field missing');
      const net = NetworkException('Socket timeout');
      const notFound = NotFoundException('Resource missing');

      expect(auth, isA<AppException>());
      expect(val, isA<AppException>());
      expect(net, isA<AppException>());
      expect(notFound, isA<AppException>());

      expect(auth.toString(), contains('AuthException: Auth failed (code: invalid_grant)'));
      expect(val.toString(), contains('ValidationException: Field missing'));
    });
  });
}
