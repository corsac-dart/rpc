library corsac_rpc.tests.middleware.version;

import 'dart:collection';

import 'package:corsac_rpc/corsac_rpc.dart';
import 'package:corsac_rpc/middleware.dart';
import 'package:test/test.dart';

void main() {
  group('AcceptHeaderApiVersionHandler:', () {
    HttpApiRequest request;

    setUp(() {
      request = new HttpApiRequest(
          'GET',
          Uri.parse('/foo'),
          {
            'accept':
                'application/vnd.foo.com+json; version=5, application/vnd.foo.com+json; version=2, application/json',
          },
          null);
    });

    test('it extracts API version from request', () {
      var next = new Next(new Queue.from([]));
      var handler = new AcceptHeaderVersionMiddleware(
          {'application/vnd.foo.com+json; version=2': '2',});
      var context = new MiddlewareContext(Uri.parse('/foo'), ApiMethod.GET);
      handler.handle(request, context, next);
      expect(context.attributes['version'], equals('2'));
    });

    test('it takes first found API version from request', () {
      var next = new Next(new Queue.from([]));
      var handler = new AcceptHeaderVersionMiddleware({
        'application/vnd.foo.com+json; version=5': '5',
        'application/vnd.foo.com+json; version=2': '2',
      });
      var context = new MiddlewareContext(Uri.parse('/foo'), ApiMethod.GET);
      handler.handle(request, context, next);
      expect(context.attributes['version'], equals('5'));
    });
  });

  group('ApiVersion', () {
    test('equality', () {
      var a = const ApiVersion('2');
      var b = new ApiVersion('2');
      expect(a, equals(b));
    });
  });

  group('UrlVersionMiddleware:', () {
    test('it extracts API version from request', () {
      var next = new Next(new Queue.from([]));
      var handler = new UrlVersionMiddleware(['v2']);
      var context = new MiddlewareContext(Uri.parse('/v2/foo'), ApiMethod.GET);
      handler.handle(null, context, next);
      expect(context.attributes['version'], equals('v2'));
      expect(context.resourceUri.path, equals('/foo'));
      expect(context.actionProperties, contains(new ApiVersion('v2')));
    });
  });
}
