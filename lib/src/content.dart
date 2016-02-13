part of corsac_rpc;

class ContentDecoderMiddleware implements Middleware {
  final Map<ContentType, ContentDecoder> decoders = new Map();

  ContentDecoderMiddleware() {
    decoders[ContentType.JSON] = new JsonContentDecoder();
    decoders[ContentType.parse('application/x-www-form-urlencoded')] =
        new FormUrlEncodedContentDecoder();
  }

  @override
  Future<HttpApiResponse> handle(
      HttpApiRequest request, MiddlewareContext context, Next next) async {
    if (['POST', 'PUT', 'PATCH'].contains(request.method.toUpperCase())) {
      var headerValue = (request.headers['content-type'] is Iterable)
          ? request.headers['content-type'].first
          : request.headers['content-type'];
      var contentType = ContentType.parse(headerValue);
      for (var decoderType in decoders.keys) {
        if (decoderType.mimeType == contentType.mimeType) {
          var data = await decoders[decoderType].decode(request);
          if (data is Map) {
            context.attributes.addAll(data);
          }
          break;
        }
      }
    }
    return next.handle(request, null, context);
  }
}

abstract class ContentDecoder {
  Future<Map<String, dynamic>> decode(HttpApiRequest request);
}

class JsonContentDecoder implements ContentDecoder {
  @override
  Future<Map<String, dynamic>> decode(HttpApiRequest request) async {
    try {
      var contentAsString = await request.bodyAsString;
      if (contentAsString is String && contentAsString.isNotEmpty)
        return JSON.decode(contentAsString);
    } on FormatException {
      throw new BadRequestApiError(['Could not parse request body.']);
    }

    return null;
  }
}

class FormUrlEncodedContentDecoder implements ContentDecoder {
  @override
  Future<Map<String, dynamic>> decode(HttpApiRequest request) async {
    try {
      var contentAsString = await request.bodyAsString;
      if (contentAsString is String && contentAsString.isNotEmpty)
        return Uri.splitQueryString(contentAsString);
    } on FormatException {
      throw new BadRequestApiError(['Could not parse request body.']);
    }

    return null;
  }
}
