part of corsac_rpc;

/// Routing middleware.
///
/// Figures out which API resource should be used for handling incoming HTTP
/// request. Invokes API resource action and updates context with returned
/// response object.
class RouterMiddleware implements Middleware {
  final Router router;
  final Kernel kernel;

  RouterMiddleware(this.router, this.kernel);

  @override
  Future handle(
      HttpRequest request, MiddlewareContext context, Next next) async {
    try {
      var matchResult = router.match(context.uri, request.method);
      if (matchResult.hasMatch) {
        final Type apiClass = matchResult.data;
        final apiResource = kernel.container.get(apiClass);
        final apiAction =
            ApiAction.match(apiClass, request.method, context.version);
        if (apiAction is ApiAction) {
          var apiRequest = new HttpApiRequest.fromHttpRequest(request);
          var response =
              await invoke(apiResource, apiAction, apiRequest, matchResult);
          if (response is! ApiResponse) {
            throw new StateError(
                'Invalid response returned. Must be instance of ApiResponse, but given ${response}');
          }
          context.response = response;
        } else {
          throw new NotFoundApiError();
        }
      } else {
        throw new NotFoundApiError();
      }
    } catch (e, stackTrace) {
      context.response = null;
      context.exception = e;
      context.stackTrace = stackTrace;
    } finally {
      return next.handle(request, context);
    }
  }

  Future<ApiResponse> invoke(Object resource, ApiAction action,
      HttpApiRequest request, MatchResult matchResult) {
    var instanceMirror = reflect(resource);
    var mirror = instanceMirror.type;
    MethodMirror method = mirror.declarations.values.firstWhere((d) {
      var meta = d.metadata.map((m) => m.reflectee).toList();
      return meta.contains(action);
    });

    var positionalParameters = method.parameters.where((_) => !_.isNamed);
    var positionalValues = positionalParameters
        .map((_) => new ApiFieldResolver(_).resolve(_, request, matchResult))
        .toList();

    var namedParameters = method.parameters.where((_) => _.isNamed);
    var namedValues = new Map<Symbol, dynamic>();
    for (var param in namedParameters) {
      namedValues[param.simpleName] =
          new ApiFieldResolver(param).resolve(param, request, matchResult);
    }

    var result = instanceMirror
        .invoke(method.simpleName, positionalValues, namedValues)
        .reflectee;

    return (result is Future) ? result : new Future.value(result);
  }
}
