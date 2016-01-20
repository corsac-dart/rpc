library corsac_rpc.tests.middleware.router;

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:corsac_kernel/corsac_kernel.dart';
import 'package:corsac_middleware/corsac_middleware.dart';
import 'package:corsac_router/corsac_router.dart';
import 'package:corsac_rpc/corsac_rpc.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class HttpRequestMock extends Mock implements HttpRequest {}

void main() {
  group('RouterMiddleware:', () {
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
      middleware = new RouterMiddleware(router, kernel.container);
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

    test('it throws when resource is not found', () async {
      var request = new HttpRequestMock();
      when(request.method).thenReturn('GET');
      when(request.headers).thenReturn({});
      when(request.requestedUri).thenReturn(Uri.parse('/not-exists'));
      var context = new MiddlewareContext(Uri.parse('/not-exists'));
      context.version = '1';

      var r = middleware.handle(request, context, next);
      expect(r, throwsA(new isInstanceOf<NotFoundApiError>()));
    });

    test('it reports when resource method is not found', () async {
      var request = new HttpRequestMock();
      when(request.method).thenReturn('POST');
      when(request.headers).thenReturn({});
      when(request.requestedUri).thenReturn(Uri.parse('/test/joe'));
      var context = new MiddlewareContext(Uri.parse('/test/joe'));
      context.version = '1';
      var r = middleware.handle(request, context, next);
      expect(r, throwsA(new isInstanceOf<NotFoundApiError>()));
    });

    test('it reports when resource version is not found', () async {
      var request = new HttpRequestMock();
      when(request.method).thenReturn('GET');
      when(request.headers).thenReturn({});
      when(request.requestedUri).thenReturn(Uri.parse('/test/joe'));
      var context = new MiddlewareContext(Uri.parse('/test/joe'));
      context.version = '100';
      var r = middleware.handle(request, context, next);
      expect(r, throwsA(new isInstanceOf<NotFoundApiError>()));
    });

    test('it supports unversioned apis', () async {
      var request = new HttpRequestMock();
      when(request.method).thenReturn('GET');
      when(request.headers).thenReturn({});
      when(request.requestedUri).thenReturn(Uri.parse('/test/joe'));
      var context = new MiddlewareContext(Uri.parse('/test/joe'));
      context.version = '*';
      await middleware.handle(request, context, next);
      expect(context.response, new isInstanceOf<ApiResponse>());
      expect(context.response.statusCode, equals(200));
      expect(context.exception, isNull);
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

  @ApiAction(method: 'GET')
  getUnversioned(String name) {
    return new ApiResponse.json(['My name is $name']);
  }
}
