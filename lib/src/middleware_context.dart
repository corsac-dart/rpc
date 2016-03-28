part of corsac_rpc;

/// Shared context used in middleware pipeline.
class MiddlewareContext {
  /// The Uri of the API resource.
  ///
  /// This is not necessarily the same as requested Uri of `HttpRequest`.
  /// Middlewares are allowed to modify this value to remove any prefix or
  /// other information not related to the actual API resource.
  ///
  /// Router component will match API resources against this value.
  Uri resourceUri;

  /// Router's match result.
  MatchResult matchResult;

  /// Properties of Api action to match against.
  ///
  /// Action having all of these properties (and only this properties)
  /// will be invoked.
  final Set<ApiActionProperty> actionProperties = new Set();

  /// Mirror of API action method to be invoked or `null` of there is no match.
  MethodMirror apiAction;

  /// Request attributes which are accesible for resource actions.
  /// Any attribute in this map can be propagated to the action when it's
  /// invoked.
  final Map<String, dynamic> attributes = new Map();

  MiddlewareContext(this.resourceUri, ApiMethod method) {
    actionProperties.add(method);
  }
}
