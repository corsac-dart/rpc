library corsac_rpc.tests.middleware.api_action_resolver;

import 'package:test/test.dart';
import 'package:corsac_rpc/corsac_rpc.dart';
import 'package:corsac_router/corsac_router.dart';
import 'dart:io';
import 'package:mockito/mockito.dart';
import 'dart:collection';
import 'package:corsac_middleware/corsac_middleware.dart';
import 'dart:mirrors';

class HttpRequestMock extends Mock implements HttpRequest {}

class HttpHeadersMock extends Mock implements HttpHeaders {}

void main() {
  group('ApiActionResolverMiddleware:', () {
    test('it resolves api action with ApiMethod property', () async {
      var middleware = new ApiActionResolverMiddleware();
      var context = new MiddlewareContext(Uri.parse('/foo'), ApiMethod.GET);
      context.matchResult = new MatchResult(null, TestApiResource, {}, {});
      var request = new HttpRequestMock();
      var next = new Next(new Queue.from([]));

      await middleware.handle(request, context, next);
      expect(context.apiAction, new isInstanceOf<MethodMirror>());
      expect(context.apiAction.simpleName, equals(#getFoo));
    });

    test('it throws NotFoundApiError if no matching action', () {
      var middleware = new ApiActionResolverMiddleware();
      var context = new MiddlewareContext(Uri.parse('/foo'), ApiMethod.POST);
      context.matchResult = new MatchResult(null, TestApiResource, {}, {});
      var request = new HttpRequestMock();
      var next = new Next(new Queue.from([]));

      expect(middleware.handle(request, context, next),
          throwsA(new isInstanceOf<NotFoundApiError>()));
    });
  });
}

class TestApiResource {
  @ApiMethod.GET
  getFoo() {}
}