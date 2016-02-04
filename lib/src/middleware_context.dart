part of corsac_rpc;

/// Shared context used in middleware pipeline.
class MiddlewareContext {
  /// Uri of the API resource.
  Uri resourceUri;

  /// Router's match result.
  MatchResult matchResult;

  /// Properties of Api action to match against.
  ///
  /// These are annotations on API action. Action matching all of these
  /// properties (and only this properties) will be invoked.
  final Set<ApiActionProperty> actionProperties = new Set();

  /// API action method to be invoked.
  MethodMirror apiAction;

  /// Response produced by middleware.
  ApiResponse response;

  final Map<String, dynamic> attributes = new Map();

  MiddlewareContext(this.resourceUri, ApiMethod method) {
    actionProperties.add(method);
  }
}
