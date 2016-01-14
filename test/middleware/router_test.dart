library corsac_rpc.tests.middleware.router;

import 'dart:mirrors';
import 'package:test/test.dart';
import 'package:corsac_router/corsac_router.dart';
import 'package:corsac_rpc/corsac_rpc.dart';
import 'package:corsac_kernel/corsac_kernel.dart';
import 'package:corsac_middleware/corsac_middleware.dart';
import 'dart:collection';
import 'package:mockito/mockito.dart';
import 'dart:io';
import 'dart:async';

class HttpRequestMock extends Mock implements HttpRequest {}

void main() {
  group('ApiFields:', () {
    Router router;
    RouterMiddleware middleware;
    Kernel kernel;
    Next next;

    setUp(() async {
      next = new Next(new Queue.from([]));
      kernel = await Kernel.build('test', {}, []);
      router = new Router();
      router.resources[new HttpResource('/test/{name}', ['GET'])] =
          TestResource;
      middleware = new RouterMiddleware(router, kernel);
    });

    test('it executes API action', () async {
      var request = new HttpRequestMock();
      when(request.method).thenReturn('GET');
      when(request.headers).thenReturn({});
      when(request.requestedUri).thenReturn(Uri.parse('/test/joe'));
      var context = new MiddlewareContext(Uri.parse('/test/joe'));
      context.version = '1';
      await middleware.handle(request, context, next);
      expect(context.response, new isInstanceOf<ApiResponse>());
      expect(context.response.statusCode, equals(200));
      expect(context.exception, isNull);
    });

    test('it resolves future responses in API actions', () async {
      var request = new HttpRequestMock();
      when(request.method).thenReturn('GET');
      when(request.headers).thenReturn({});
      when(request.requestedUri).thenReturn(Uri.parse('/test/joe'));
      var context = new MiddlewareContext(Uri.parse('/test/joe'));
      context.version = '2';
      await middleware.handle(request, context, next);
      expect(context.response, new isInstanceOf<ApiResponse>());
      expect(context.response.statusCode, equals(200));
      expect(context.exception, isNull);
    });

    test('it catches errors in API actions', () async {
      var request = new HttpRequestMock();
      when(request.method).thenReturn('GET');
      when(request.headers).thenReturn({});
      when(request.requestedUri).thenReturn(Uri.parse('/test/joe'));
      var context = new MiddlewareContext(Uri.parse('/test/joe'));
      context.version = '3';
      await middleware.handle(request, context, next);
      expect(context.response, isNull);
      expect(context.exception, new isInstanceOf<ArgumentError>());
    });

    test('it catches errors in futures returned from API actions', () async {
      var request = new HttpRequestMock();
      when(request.method).thenReturn('GET');
      when(request.headers).thenReturn({});
      when(request.requestedUri).thenReturn(Uri.parse('/test/joe'));
      var context = new MiddlewareContext(Uri.parse('/test/joe'));
      context.version = '4';
      await middleware.handle(request, context, next);
      expect(context.response, isNull);
      expect(context.exception, new isInstanceOf<ArgumentError>());
      expect((context.exception as ArgumentError).message, 'Wrong name');
    });

    test('it reports when resource not found', () async {
      var request = new HttpRequestMock();
      when(request.method).thenReturn('GET');
      when(request.headers).thenReturn({});
      when(request.requestedUri).thenReturn(Uri.parse('/not-exists'));
      var context = new MiddlewareContext(Uri.parse('/not-exists'));
      context.version = '1';
      await middleware.handle(request, context, next);
      expect(context.response, isNull);
      expect(context.exception, new isInstanceOf<NotFoundApiError>());
    });

    test('it reports when resource method is not found', () async {
      var request = new HttpRequestMock();
      when(request.method).thenReturn('POST');
      when(request.headers).thenReturn({});
      when(request.requestedUri).thenReturn(Uri.parse('/test/joe'));
      var context = new MiddlewareContext(Uri.parse('/test/joe'));
      context.version = '1';
      await middleware.handle(request, context, next);
      expect(context.response, isNull);
      expect(context.exception, new isInstanceOf<NotFoundApiError>());
    });

    test('it reports when resource version is not found', () async {
      var request = new HttpRequestMock();
      when(request.method).thenReturn('GET');
      when(request.headers).thenReturn({});
      when(request.requestedUri).thenReturn(Uri.parse('/test/joe'));
      var context = new MiddlewareContext(Uri.parse('/test/joe'));
      context.version = '100';
      await middleware.handle(request, context, next);
      expect(context.response, isNull);
      expect(context.exception, new isInstanceOf<NotFoundApiError>());
    });
  });
}

@ApiResource(path: '/test/{name}')
class TestResource {
  @ApiAction(method: 'GET', versions: const ['1'])
  getTest(String name, {DateTime from, int limit, String q}) {
    return new ApiResponse.json([name]);
  }

  @ApiAction(method: 'GET', versions: const ['2'])
  getFutureTest(String name) {
    return new Future(() {
      return new ApiResponse.json(['My name is $name']);
    });
  }

  @ApiAction(method: 'GET', versions: const ['3'])
  getFail(String name) {
    throw new ArgumentError('Wrong name');
  }

  @ApiAction(method: 'GET', versions: const ['4'])
  getFutureFail(String name) {
    return new Future(() {
      throw new ArgumentError('Wrong name');
    });
  }
}
