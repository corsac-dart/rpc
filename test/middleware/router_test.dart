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
  });
}

@ApiResource(path: '/test/{name}')
class TestResource {
  @ApiMethod.GET
  getTest(String name) {
    return new HttpApiResponse.json([name]);
  }
}
