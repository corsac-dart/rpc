library corsac_rpc.tests.api_responses;

import 'dart:mirrors';
import 'package:test/test.dart';
import 'package:corsac_router/corsac_router.dart';
import 'package:corsac_rpc/corsac_rpc.dart';
import 'dart:convert';
import 'dart:io';

void main() {
  group('ApiResponse:', () {
    Codec bytesToJson = JSON.fuse(UTF8);

    test('it creates json response', () async {
      var response = new ApiResponse.json({'foo': 'bar'},
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
