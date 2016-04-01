library corsac_rpc.tests.middleware.api_action_invoker;

import 'dart:async';
import 'dart:collection';
import 'dart:mirrors';

import 'package:corsac_kernel/corsac_kernel.dart';
import 'package:corsac_router/corsac_router.dart';
import 'package:corsac_rpc/corsac_rpc.dart';
import 'package:test/test.dart';

void main() {
  group('ApiActionInvokerMiddleware:', () {
    test('it resolves future responses', () async {
      var mirror = reflectClass(TestApiResource);
      var kernel = await Kernel.build('test', {}, []);
      var middleware = new ActionInvokerMiddleware(kernel);

      var apiRequest =
          new HttpApiRequest('GET', Uri.parse('/test/foo'), {}, null);
      var context =
          new MiddlewareContext(Uri.parse('/test/foo'), ApiMethod.GET);
      context.matchResult =
          new MatchResult(null, TestApiResource, {'name': 'foo'}, {});
      context.apiAction = mirror.declarations[#getFutureTest];
      context.attributes['name'] = 'foo';
      var next = new Next(new Queue.from([]));

      var response = await middleware.handle(apiRequest, context, next);
      expect(response, new isInstanceOf<HttpApiResponse>());
    });

    test('it throws StateError if no response is returned', () async {
      var mirror = reflectClass(TestApiResource);
      var kernel = await Kernel.build('test', {}, []);
      var middleware = new ActionInvokerMiddleware(kernel);

      var apiRequest =
          new HttpApiRequest('GET', Uri.parse('/test/foo'), {}, null);
      var context =
          new MiddlewareContext(Uri.parse('/test/foo'), ApiMethod.GET);
      context.matchResult =
          new MatchResult(null, TestApiResource, {'name': 'foo'}, {});
      context.apiAction = mirror.declarations[#getFail];
      context.attributes['name'] = 'foo';
      var next = new Next(new Queue.from([]));

      expect(middleware.handle(apiRequest, context, next),
          throwsA(new isInstanceOf<StateError>()));
    });
  });
}

@ApiResource(path: '/test/{name}')
class TestApiResource {
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
    return null;
  }
}
