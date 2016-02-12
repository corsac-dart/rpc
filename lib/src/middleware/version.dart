part of corsac_rpc.middleware;

/// Annotation to be used on action methods of API resources.
class ApiVersion implements ApiActionProperty {
  final String version;
  const ApiVersion(this.version);

  @override
  bool operator ==(ApiVersion other) =>
      (other is ApiVersion && other.version == this.version);

  @override
  int get hashCode => version.hashCode;
}

/// Extracts API version from the request's URL path. It will also update
/// [MiddlewareContext.resourceUri] with updated path (excluding version prefix).
///
/// You must provide [supportedVersions] so that middleware can validate the
/// version in the URL.
class UrlVersionMiddleware implements Middleware {
  final Iterable<String> supportedVersions;

  UrlVersionMiddleware(this.supportedVersions);

  @override
  Future<HttpApiResponse> handle(
      HttpApiRequest request, MiddlewareContext context, Next next) {
    var segments = new List<String>.from(context.resourceUri.pathSegments);
    if (supportedVersions.contains(segments.first)) {
      context.actionProperties.add(new ApiVersion(segments.first));
      context.attributes['version'] = segments.first;
      segments.removeAt(0);
      var newPath = '/' + segments.join('/');
      context.resourceUri = context.resourceUri.replace(path: newPath);
    } else {
      throw new NotFoundApiError();
    }

    return next.handle(request, null, context);
  }
}

/// Extracts API version from the Accept header.
///
/// You must provide a map for mime types containing version information to
/// actual version number. Example:
///
///     new AcceptHeaderVersionMiddleware({
///       // in the mime type attribute:
///       'application/vnd.foo.com+json; version=1': '1',
///       'application/vnd.foo.com+json; version=2': '2',
///       // or in the mime type name itself:
///       'application/vnd.foo.com.v1+json': '1',
///     });
class AcceptHeaderVersionMiddleware implements Middleware {
  final Map<String, String> mimeTypesMap;

  AcceptHeaderVersionMiddleware(this.mimeTypesMap);

  @override
  Future<HttpApiResponse> handle(
      HttpApiRequest request, MiddlewareContext context, Next next) {
    var value = request.headers['accept'];
    for (var mime in mimeTypesMap.keys) {
      if (value.contains(mime)) {
        context.attributes['version'] = mimeTypesMap[mime];
        context.actionProperties.add(new ApiVersion(mimeTypesMap[mime]));
        break;
      }
    }

    if (context.attributes.containsKey('version')) {
      return next.handle(request, null, context);
    } else {
      throw new NotFoundApiError();
    }
  }
}
