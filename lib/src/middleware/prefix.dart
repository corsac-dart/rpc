part of corsac_rpc.middleware;

/// Strips path prefix from the request Uri in the middleware context.
///
/// Other middlewares can still access original path in the provided `request`
/// object.
class PrefixMiddleware implements Middleware {
  final String prefix;

  PrefixMiddleware(this.prefix);

  @override
  Future handle(HttpRequest request, MiddlewareContext context, Next next) {
    if (prefix.isNotEmpty) {
      var path = context.resourceUri.path;
      if (!path.startsWith(prefix)) {
        throw new NotFoundApiError();
      }
      context.resourceUri =
          context.resourceUri.replace(path: path.replaceFirst(prefix, ''));
    }
    return next.handle(request, context);
  }
}
