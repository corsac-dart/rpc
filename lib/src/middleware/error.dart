part of corsac_rpc;

/// Handler function which returns [ApiResponse] for given [exception] and
/// [stackTrace].
typedef ApiResponse ApiErrorHandler(exception, StackTrace stackTrace);

/// Responsible for converting any errors occured during handling of a request
/// into a response.
class ErrorMiddleware implements Middleware {
  final ApiErrorHandler handler;

  ErrorMiddleware(this.handler);

  @override
  Future handle(
      HttpRequest request, MiddlewareContext context, Next next) async {
    if (context.exception != null) {
      context.response = handler(context.exception, context.stackTrace);
    }

    return next.handle(request, context);
  }
}
