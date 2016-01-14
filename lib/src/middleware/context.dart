part of corsac_rpc;

/// Shared context used in middleware pipeline.
class MiddlewareContext {
  /// Uri which represents API resource
  Uri uri;

  /// API version
  String version;

  /// Response produced by middleware.
  ApiResponse response;

  /// Error occured during handling of request.
  Object exception;

  /// Stack trace for the error stored in [exception].
  StackTrace stackTrace;

  MiddlewareContext(this.uri);
}
