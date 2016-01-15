library corsac_rpc.tests.middleware.version;

import 'package:test/test.dart';
import 'package:corsac_rpc/corsac_rpc.dart';
import 'dart:io';
import 'package:mockito/mockito.dart';

class HttpRequestMock extends Mock implements HttpRequest {}

class HttpHeadersMock extends Mock implements HttpHeaders {}

void main() {
  group('AcceptHeaderApiVersionHandler:', () {
    HttpRequest request;

    setUp(() {
      request = new HttpRequestMock();
      var headers = new HttpHeadersMock();
      when(request.headers).thenReturn(headers);
      when(headers.value('Accept')).thenReturn(
          'application/vnd.foo.com+json; version=5, application/vnd.foo.com+json; version=2, application/json');
    });

    test('it extracts API version from request', () {
      var handler = new AcceptHeaderApiVersionHandler(
          {'application/vnd.foo.com+json; version=2': '2',});
      var context = new MiddlewareContext(Uri.parse('/foo'));
      handler.handle(request, context);
      expect(context.version, equals('2'));
    });

    test('it takes first found API version from request', () {
      var handler = new AcceptHeaderApiVersionHandler({
        'application/vnd.foo.com+json; version=5': '5',
        'application/vnd.foo.com+json; version=2': '2',
      });
      var context = new MiddlewareContext(Uri.parse('/foo'));
      handler.handle(request, context);
      expect(context.version, equals('5'));
    });
  });

  group('UrlPrefixedApiVersionHandler:', () {
    HttpRequest request;

    setUp(() {
      request = new HttpRequestMock();
    });

    test('it extracts API version from request', () {
      var handler = new UrlPrefixedApiVersionHandler();
      var context = new MiddlewareContext(Uri.parse('/v2/foo'));
      handler.handle(request, context);
      expect(context.version, equals('2'));
      expect(context.uri.path, equals('/foo'));

      context = new MiddlewareContext(Uri.parse('/2.3/foo'));
      handler.handle(request, context);
      expect(context.version, equals('2.3'));
      expect(context.uri.path, equals('/foo'));
    });
  });
}
