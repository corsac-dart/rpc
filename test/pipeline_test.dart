library corsac_rpc.test.pipeline;

import 'dart:async';
import 'dart:convert';

import 'package:corsac_rpc/http.dart';
import 'package:corsac_rpc/pipeline.dart';
import 'package:test/test.dart';

void main() {
  group('Pipeline:', () {
    test('it executes one handler', () async {
      Pipeline p = new Pipeline([new SimpleMiddleware()].toSet());
      var request = new HttpApiRequest('GET', Uri.parse('/foo'), {}, null);
      var response = await p.handle(request, null);
      var body = await UTF8.decodeStream(response.body);
      expect(body, equals('Test'));
    });

    test('it executes two handlers', () async {
      Pipeline p = new Pipeline(
          [new ChainingMiddleware(), new SimpleMiddleware()].toSet());

      var request = new HttpApiRequest('GET', Uri.parse('/foo'), {}, null);
      var response = await p.handle(request, null);
      var body = await UTF8.decodeStream(response.body);
      expect(body, equals('Test'));
    });

    test('it executes beforeHandlers first', () async {
      var p = new Pipeline([new SimpleMiddleware()].toSet());
      p.beforeHandlers.add(new BeforeMiddleware());
      var request = new HttpApiRequest('GET', Uri.parse('/foo'), {}, null);
      var response = await p.handle(request, new Map());
      var body = await UTF8.decodeStream(response.body);
      expect(body, equals('BeforeTest'));
    });
  });
}

class SimpleMiddleware implements Middleware {
  @override
  Future<HttpApiResponse> handle(
      HttpApiRequest request, Map context, Next next) {
    var body = 'Test';
    if (context is Map && context.containsKey('prepend')) {
      body = context['prepend'] + body;
    }
    return new Future.value(new HttpApiResponse.text(body));
  }
}

class ChainingMiddleware implements Middleware {
  @override
  Future<HttpApiResponse> handle(
      HttpApiRequest request, Map context, Next next) async {
    return next.handle(request, null, context);
  }
}

class BeforeMiddleware implements Middleware {
  @override
  Future handle(HttpApiRequest request, Map context, Next next) {
    context['prepend'] = 'Before';
    return next.handle(request, null, context);
  }
}
