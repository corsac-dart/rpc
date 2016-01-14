part of corsac_rpc;

class ApiResponse {
  final Stream<List<int>> body;
  final ContentType contentType;
  final int statusCode;
  final Map<String, dynamic> headers;

  static final Codec _jsonToBytes = JSON.fuse(UTF8);

  ApiResponse(this.body, this.contentType,
      {this.statusCode: HttpStatus.OK, this.headers});

  ApiResponse.json(Object data,
      {int statusCode: HttpStatus.OK, Map<String, dynamic> headers})
      : this(new Stream.fromIterable([_jsonToBytes.encode(data)]),
            ContentType.JSON,
            statusCode: statusCode, headers: headers);
}
