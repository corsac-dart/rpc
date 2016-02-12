library corsac_rpc.tests.middleware.router;

import 'dart:async';
import 'dart:collection';

import 'package:corsac_router/corsac_router.dart';
import 'package:corsac_rpc/corsac_rpc.dart';
import 'package:test/test.dart';

// TODO: update commented out tests.
void main() {
  group('RouterMiddleware:', () {
    RouterMiddleware middleware;
    Next next;

    setUp(() async {
      next = new Next(new Queue.from([]));
      middleware = new RouterMiddleware([TestResource]);
    });

    test('it populates context with match result', () async {
      var request = new HttpApiRequest('GET', Uri.parse('/test/joe'), {}, null);
      var context =
          new MiddlewareContext(Uri.parse('/test/joe'), ApiMethod.GET);
      await middleware.handle(request, context, next);
      expect(context.matchResult, new isInstanceOf<MatchResult>());
    });
    //
    // test('it resolves future responses in API actions', () async {
    //   var request = new HttpRequestMock();
    //   when(request.method).thenReturn('GET');
    //   when(request.headers).thenReturn({});
    //   when(request.requestedUri).thenReturn(Uri.parse('/test/joe'));
    //   var context = new MiddlewareContext(Uri.parse('/test/joe'));
    //   context.version = '2';
    //   await middleware.handle(request, context, next);
    //   expect(context.response, new isInstanceOf<ApiResponse>());
    //   expect(context.response.statusCode, equals(200));
    // });
    //
    // test('it throws when resource is not found', () async {
    //   var request = new HttpRequestMock();
    //   when(request.method).thenReturn('GET');
    //   when(request.headers).thenReturn({});
    //   when(request.requestedUri).thenReturn(Uri.parse('/not-exists'));
    //   var context = new MiddlewareContext(Uri.parse('/not-exists'));
    //   context.version = '1';
    //
    //   var r = middleware.handle(request, context, next);
    //   expect(r, throwsA(new isInstanceOf<NotFoundApiError>()));
    // });
    //
    // test('it reports when resource method is not found', () async {
    //   var request = new HttpRequestMock();
    //   when(request.method).thenReturn('POST');
    //   when(request.headers).thenReturn({});
    //   when(request.requestedUri).thenReturn(Uri.parse('/test/joe'));
    //   var context = new MiddlewareContext(Uri.parse('/test/joe'));
    //   context.version = '1';
    //   var r = middleware.handle(request, context, next);
    //   expect(r, throwsA(new isInstanceOf<NotFoundApiError>()));
    // });
    //
    // test('it reports when resource version is not found', () async {
    //   var request = new HttpRequestMock();
    //   when(request.method).thenReturn('GET');
    //   when(request.headers).thenReturn({});
    //   when(request.requestedUri).thenReturn(Uri.parse('/test/joe'));
    //   var context = new MiddlewareContext(Uri.parse('/test/joe'));
    //   context.version = '100';
    //   var r = middleware.handle(request, context, next);
    //   expect(r, throwsA(new isInstanceOf<NotFoundApiError>()));
    // });
    //
    // test('it supports unversioned apis', () async {
    //   var request = new HttpRequestMock();
    //   when(request.method).thenReturn('GET');
    //   when(request.headers).thenReturn({});
    //   when(request.requestedUri).thenReturn(Uri.parse('/test/joe'));
    //   var context = new MiddlewareContext(Uri.parse('/test/joe'));
    //   context.version = '*';
    //   await middleware.handle(request, context, next);
    //   expect(context.response, new isInstanceOf<ApiResponse>());
    //   expect(context.response.statusCode, equals(200));
    // });
  });
}

@ApiResource(path: '/test/{name}')
class TestResource {
  @ApiMethod.GET
  getTest(String name, {DateTime from, int limit, String q}) {
    return new HttpApiResponse.json([name]);
  }

  @ApiMethod.GET
  getFutureTest(String name) {
    return new Future(() {
      return new HttpApiResponse.json(['My name is $name']);
    });
  }

  @ApiMethod.GET
  getFail(String name) {
    throw new ArgumentError('Wrong name');
  }

  @ApiMethod.GET
  getFutureFail(String name) {
    return new Future(() {
      throw new ArgumentError('Wrong name');
    });
  }

  @ApiMethod.GET
  getUnversioned(String name) {
    return new HttpApiResponse.json(['My name is $name']);
  }
}
