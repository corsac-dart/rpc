part of corsac_rpc;

/// Strips path prefix from the request Uri.
class PrefixMiddleware implements Middleware {
  final String prefix;

  PrefixMiddleware(this.prefix);

  @override
  Future handle(HttpRequest request, MiddlewareContext context, Next next) {
    if (prefix.isNotEmpty) {
      var path = context.uri.path;
      if (!path.startsWith(prefix)) {
        // Practically should not be possible but we handle it here and return 404.
        context.response = new ApiResponse.json({'errors': 'Not found.'},
            statusCode: HttpStatus.NOT_FOUND);
        return new Future.value();
      }
      context.uri = context.uri.replace(path: path.replaceFirst(prefix, ''));
    }
    return next.handle(request, context);
  }
}
