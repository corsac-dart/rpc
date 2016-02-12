library corsac_rpc.http;

import 'dart:async';
import 'dart:io';
import 'dart:convert';

class HttpApiRequest {
  final String method;

  /// Requested URI.
  final Uri uri;

  /// HTTP headers of this request.
  final Map<String, dynamic> headers;

  /// Body of this request as a byte stream.
  ///
  /// To read request's body as string use [bodyAsString] field.
  final Stream<List<int>> body;

  // Request cookies.
  final List<Cookie> cookies;

  String _bodyAsString;

  /// Body of this request converted into a string.
  ///
  /// Once called it will consume stream stored in [body]. No further
  /// subscriptions to [body] will be allowed.
  Future<String> get bodyAsString async {
    if (_bodyAsString == null) {
      _bodyAsString = await UTF8.decodeStream(body);
    }
    return _bodyAsString;
  }

  factory HttpApiRequest(String httpMethod, Uri uri,
      Map<String, dynamic> headers, Stream<List<int>> body,
      {List<Cookie> cookies}) {
    var headersLowerCase = new Map<String, dynamic>();
    headers.forEach((String key, dynamic value) =>
        headersLowerCase[key.toLowerCase()] = value);

    return new HttpApiRequest._(
        httpMethod, uri, headersLowerCase, cookies, body);
  }

  factory HttpApiRequest.fromHttpRequest(HttpRequest request) {
    var headers = new Map<String, dynamic>();
    request.headers
        .forEach((String key, dynamic value) => headers[key] = value);

    return new HttpApiRequest._(request.method, request.requestedUri, headers,
        request.cookies, request);
  }

  HttpApiRequest._(
      this.method, this.uri, this.headers, this.cookies, this.body);
}

class HttpApiResponse {
  final Stream<List<int>> body;
  final ContentType contentType;
  final int statusCode;
  final Map<String, dynamic> headers;

  static final Codec _jsonToBytes = JSON.fuse(UTF8);

  HttpApiResponse(this.body, this.contentType,
      {this.statusCode: HttpStatus.OK, this.headers});

  HttpApiResponse.json(Object data,
      {int statusCode: HttpStatus.OK, Map<String, dynamic> headers})
      : this(new Stream.fromIterable([_jsonToBytes.encode(data)]),
            ContentType.JSON,
            statusCode: statusCode, headers: headers);

  HttpApiResponse.text(String text,
      {int statusCode: HttpStatus.OK, Map<String, dynamic> headers})
      : this(new Stream.fromIterable([UTF8.encode(text)]), ContentType.TEXT,
            statusCode: statusCode, headers: headers);
}
