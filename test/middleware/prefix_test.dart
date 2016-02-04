library corsac_rpc.tests.middleware.prefix;

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:corsac_middleware/corsac_middleware.dart';
import 'package:corsac_rpc/corsac_rpc.dart';
import 'package:corsac_rpc/middleware.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class HttpRequestMock extends Mock implements HttpRequest {}

void main() {
  group('PrefixMiddleware:', () {
    PrefixMiddleware prefixMiddleware;

    setUp(() async {
      prefixMiddleware = new PrefixMiddleware('/api');
    });

    test('it removes prefix from the path', () async {
      var request = new HttpRequestMock();
      var context =
          new MiddlewareContext(Uri.parse('/api/test'), ApiMethod.GET);
      var next = new Next(new Queue.from([]));
      var r = prefixMiddleware.handle(request, context, next);
      expect(r, new isInstanceOf<Future>());
      await r;
      expect(context.resourceUri.path, equals('/test'));
    });

    test('it throws NotFoundApiError if path does not start with prefix',
        () async {
      var request = new HttpRequestMock();
      var context =
          new MiddlewareContext(Uri.parse('/bad/test'), ApiMethod.GET);
      var next = new Next(new Queue.from([]));
      expect(() => prefixMiddleware.handle(request, context, next),
          throwsA(new isInstanceOf<NotFoundApiError>()));
    });
  });
}
