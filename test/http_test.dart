library corsac_rpc.tests.http;

import 'package:test/test.dart';
import 'package:corsac_rpc/http.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

void main() {
  group('HttpApiRequest:', () {
    test('api request body can be read as string', () async {
      var controller = new StreamController<List<int>>();
      controller.add(UTF8.encode('body'));
      controller.close();
      var request =
          new HttpApiRequest('GET', Uri.parse('/foo'), {}, controller.stream);
      var body1 = await request.bodyAsString;
      var body2 = await request.bodyAsString;
      expect(body1, equals('body'));
      expect(body2, equals('body'));
    });
  });

  group('HttpApiResponse:', () {
    Codec bytesToJson = JSON.fuse(UTF8);

    test('it creates json response', () async {
      var response = new HttpApiResponse.json({'foo': 'bar'},
          statusCode: HttpStatus.NOT_FOUND, headers: {'Foo': 'Bar'});
      var data = await response.body.first;
      var json = bytesToJson.decode(data);
      expect(json, equals({'foo': 'bar'}));
      expect(response.contentType, ContentType.JSON);
      expect(response.statusCode, HttpStatus.NOT_FOUND);
      expect(response.headers, {'Foo': 'Bar'});
    });
  });
}
