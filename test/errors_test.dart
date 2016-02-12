library corsac_rpc.tests.errors;

import 'package:test/test.dart';
import 'package:corsac_rpc/corsac_rpc.dart';
import 'dart:io';

void main() {
  group('Errors:', () {
    test('NotFoundApiError', () {
      var error = new NotFoundApiError();
      expect(error.statusCode, equals(HttpStatus.NOT_FOUND));
      expect(error.message, equals('Requested resource not found.'));
    });

    test('BadRequestApiError', () {
      var error = new BadRequestApiError(['error']);
      expect(error.statusCode, equals(HttpStatus.BAD_REQUEST));
      expect(error.message, equals('Bad request.'));
      expect(error.errors, contains('error'));
    });

    test('UnauthorizedApiError', () {
      var error = new UnauthorizedApiError();
      expect(error.statusCode, equals(HttpStatus.UNAUTHORIZED));
      expect(error.message, equals('Unauthorized.'));
    });

    test('InternalServerApiError', () {
      var error = new InternalServerApiError('Error', null);
      expect(error.statusCode, equals(HttpStatus.INTERNAL_SERVER_ERROR));
      expect(error.message, equals('Internal server error.'));
      expect(error.exception, equals('Error'));
    });
  });
}
