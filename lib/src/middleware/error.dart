part of corsac_rpc;

/// Responsible for catching any errors occured during handling of a request
/// and storing error information in the [MiddlewareContext].
class ErrorMiddleware implements Middleware {
  @override
  Future handle(HttpRequest request, MiddlewareContext context, Next next) {
    Future f;
    try {
      f = next.handle(request, context).catchError((e, stackTrace) {
        context.exception = e;
        context.stackTrace = stackTrace;
      });
    } catch (e, stackTrace) {
      context.exception = e;
      context.stackTrace = stackTrace;
      f = new Future.value();
    } finally {
      return f;
    }
  }
}
