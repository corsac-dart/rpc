library corsac_rpc.tests.middleware.error;

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:corsac_middleware/corsac_middleware.dart';
import 'package:corsac_rpc/corsac_rpc.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class HttpRequestMock extends Mock implements HttpRequest {}

void main() {
  group('ErrorMiddleware:', () {
    ErrorMiddleware errorMiddleware;

    setUp(() async {
      errorMiddleware = new ErrorMiddleware();
    });

    test('it catches sync errors and updates the context', () async {
      var request = new HttpRequestMock();
      var context = new MiddlewareContext(Uri.parse('/test/joe'));
      var next = new Next(new Queue.from([new FailingMiddleware()]));
      var r = errorMiddleware.handle(request, context, next);
      expect(r, new isInstanceOf<Future>());
      await r;
      expect(context.exception, equals('I failed'));
      expect(context.stackTrace, new isInstanceOf<StackTrace>());
    });

    test('it catches async errors and updates the context', () async {
      var request = new HttpRequestMock();
      var context = new MiddlewareContext(Uri.parse('/test/joe'));
      var next = new Next(new Queue.from([new AsyncFailingMiddleware()]));
      var r = errorMiddleware.handle(request, context, next);
      expect(r, new isInstanceOf<Future>());
      await r;
      expect(context.exception, equals('I failed asynchronously'));
      expect(context.stackTrace, new isInstanceOf<StackTrace>());
    });
  });
}

class FailingMiddleware implements Middleware {
  @override
  Future handle(HttpRequest request, Object context, Next next) {
    throw 'I failed';
  }
}

class AsyncFailingMiddleware implements Middleware {
  @override
  Future handle(HttpRequest request, Object context, Next next) {
    return new Future(() {
      throw 'I failed asynchronously';
    });
  }
}
