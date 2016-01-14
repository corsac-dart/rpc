part of corsac_rpc;

abstract class ApiVersionHandler {
  void handle(HttpRequest request, MiddlewareContext context);
}

/// Middleware responsible for extracting requested API version from the
/// request and populating it in the middleware context.
///
/// Uses implementations of [ApiVersionHandler] which encapsulate details of
/// how API version is represented in the request and how to extract it.
class ApiVersionMiddleware implements Middleware {
  final ApiVersionHandler handler;

  ApiVersionMiddleware(this.handler);

  @override
  Future handle(HttpRequest request, MiddlewareContext context, Next next) {
    handler.handle(request, context);
    return next.handle(request, context);
  }
}

/// Extracts API version from the request's URL path. It will also update
/// `MiddlewareContext.uri` with updated path (excluding version prefix).
///
/// Examples of URLs containing version numbers and results of this handler:
///
///     URL          => VERSION => NEW URI PATH
///     /v1/users    => 1       => /users
///     /v1.2/users  => 1.2     => /users
///     /1.2.3/users => 1.2.3   => /users
///
/// That is, if `v` prefix is present it will be stripped from the version
/// number.
class UrlPrefixedApiVerionHandler implements ApiVersionHandler {
  @override
  void handle(HttpRequest request, MiddlewareContext context) {
    var segments = new List<String>.from(context.uri.pathSegments);
    if (segments.first.startsWith('v')) {
      context.version = segments.first.replaceFirst('v', '');
    } else {
      context.version = segments.first;
    }

    segments.removeAt(0);
    var newPath = '/' + segments.join('/');
    context.uri = context.uri.replace(path: newPath);
  }
}

/// Extracts API version from the Accept header.
///
/// You must provide a map for mime types containing version information to
/// actual version number. Example:
///
///     new AcceptHeaderApiVersionHandler({
///       // in the mime type attribute:
///       'application/vnd.foo.com+json; version=1': '1',
///       'application/vnd.foo.com+json; version=2': '2',
///       // or in the mime type name itself:
///       'application/vnd.foo.com.v1+json': '1',
///     });
class AcceptHeaderApiVersionHandler implements ApiVersionHandler {
  final Map<String, String> mimeTypesMap;

  AcceptHeaderApiVersionHandler(this.mimeTypesMap);

  @override
  void handle(HttpRequest request, MiddlewareContext context) {
    var value = request.headers.value('Accept');
    for (var mime in mimeTypesMap.keys) {
      if (value.contains(mime)) {
        context.version = mimeTypesMap[mime];
        break;
      }
    }
  }
}
