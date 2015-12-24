library corsac_http_application.test.controllers;

import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:corsac_http_application/corsac_http_application.dart';
import 'dart:io';
import 'package:corsac_router/corsac_router.dart';
import 'dart:convert';

class MockHttpRequest extends Mock implements HttpRequest {}

main() {
  group('Class-based controllers:', () {
    ClassBasedControllerInvoker invoker;
    MockHttpRequest request;

    setUp(() {
      invoker = new ClassBasedControllerInvoker(TestController);
      request = new MockHttpRequest();
    });

    test('it can invoke simple controller method', () async {
      when(request.method).thenReturn('GET');
      var match =
          new MatchResult(new HttpResource('/test', ['GET']), invoker, {});

      ControllerResponse result =
          await invoker.invoke(new TestController(), request, match);

      expect(result, new isInstanceOf<ControllerResponse>());
      expect(result.statusCode, equals(HttpStatus.OK));
      expect(result.contentType, equals(ContentType.JSON));
      expect(result.content, equals(JSON.encode('ok')));
    });

    test('it can resolve positional parameters', () async {
      when(request.method).thenReturn('PUT');
      var match = new MatchResult(
          new HttpResource('/test/{userId}/{action}', ['PUT']),
          invoker,
          {'userId': '342', 'action': 'delete',});

      ControllerResponse result =
          await invoker.invoke(new TestController(), request, match);

      expect(result, new isInstanceOf<ControllerResponse>());
      expect(result.statusCode, equals(HttpStatus.OK));
      expect(result.contentType, equals(ContentType.JSON));
      expect(result.content, equals(JSON.encode('342:delete')));
    });

    test('it can resolve positional parameters regardless of order', () async {
      when(request.method).thenReturn('PUT');
      var match = new MatchResult(
          new HttpResource('/test/{action}/{userId}', ['PUT']),
          invoker,
          {'action': 'delete', 'userId': '342',});

      ControllerResponse result =
          await invoker.invoke(new TestController(), request, match);

      expect(result, new isInstanceOf<ControllerResponse>());
      expect(result.statusCode, equals(HttpStatus.OK));
      expect(result.contentType, equals(ContentType.JSON));
      expect(result.content, equals(JSON.encode('342:delete')));
    });
  });
}

class TestController extends Object with ControllerResponses {
  @HttpMethod('GET')
  getSimple() {
    return json('ok');
  }

  @HttpMethod('PUT')
  putWithParams(String userId, String action) {
    return json('${userId}:${action}');
  }
}
