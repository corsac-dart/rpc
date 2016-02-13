library corsac_rpc.tests.content;

import 'dart:async';
import 'dart:convert';

import 'package:corsac_rpc/corsac_rpc.dart';
import 'package:test/test.dart';

void main() {
  group('Content Decoders:', () {
    test('it can decode json content', () async {
      var data = {'foo': 12321};
      var content = JSON.encode(data);

      var stream = new Stream.fromIterable([UTF8.encode(content)]);
      var request = new HttpApiRequest('POST', Uri.parse('/foo'), {}, stream);
      var decoder = new JsonContentDecoder();
      var result = await decoder.decode(request);
      expect(result, isMap);
      expect(result, containsPair('foo', 12321));
    });

    test('it throws BadRequestApiError if json is invalid', () async {
      var content = '{"foo":}';

      var stream = new Stream.fromIterable([UTF8.encode(content)]);
      var request = new HttpApiRequest('POST', Uri.parse('/foo'), {}, stream);
      var decoder = new JsonContentDecoder();
      expect(decoder.decode(request),
          throwsA(new isInstanceOf<BadRequestApiError>()));
    });

    test('it can decode form url encoded content', () async {
      var content = 'foo=1231&bar=zoo';

      var stream = new Stream.fromIterable([UTF8.encode(content)]);
      var request = new HttpApiRequest('POST', Uri.parse('/foo'), {}, stream);
      var decoder = new FormUrlEncodedContentDecoder();
      var result = await decoder.decode(request);
      expect(result, isMap);
      expect(result, containsPair('foo', '1231'));
      expect(result, containsPair('bar', 'zoo'));
    });
  });
}
