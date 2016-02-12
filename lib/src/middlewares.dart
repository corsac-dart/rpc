part of corsac_rpc;

/// Routing middleware.
///
/// Matches `HttpRequest` to an API resource and stores `MatchResult` in the
/// middleware context.
class RouterMiddleware implements Middleware {
  final Iterable<Type> apiResources;

  Router _router;

  RouterMiddleware(this.apiResources) {
    _router = new Router();
    for (var apiClass in apiResources) {
      var apiResource = new ApiResource.fromClass(apiClass);
      var apiMethods = ApiMethod.list(apiClass).map((_) => _.method).toSet();
      var httpResource = new HttpResource(apiResource.path, apiMethods);

      if (_router.resources.containsKey(httpResource)) {
        throw new StateError(
            'HttpResource already registered for ${httpResource.path}');
      }
      _router.resources[httpResource] = apiClass;
    }
  }

  @override
  Future<HttpApiResponse> handle(
      HttpApiRequest request, MiddlewareContext context, Next next) async {
    context.matchResult = _router.match(context.resourceUri, request.method);
    if (context.matchResult.hasMatch) {
      return next.handle(request, null, context);
    } else {
      throw new NotFoundApiError();
    }
  }
}

/// Default implementation of access control middleware.
///
/// Always grants access to all resources. To use custom implementation one need
/// to register it with the Kernel:
///
///     class MyApiServerKernelModule extends ApiServerKernelModule {
///       @override
///       Map getServiceConfiguration(String environment) {
///         var config = super.getServiceConfiguration(environment);
///         config[AccessControlMiddleware] = MyAccessControlMiddleware;
///         return config;
///       }
///     }
class AccessControlMiddleware implements Middleware {
  @override
  Future<HttpApiResponse> handle(
      HttpApiRequest request, MiddlewareContext context, Next next) {
    return next.handle(request, null, context);
  }
}

/// Invokes API action.
class ApiActionInvokerMiddleware implements Middleware {
  final Kernel kernel;

  ApiActionInvokerMiddleware(this.kernel);

  @override
  Future<HttpApiResponse> handle(
      HttpApiRequest request, MiddlewareContext context, Next next) async {
    Type apiClass = context.matchResult.data;
    var apiResource = kernel.get(apiClass);

    var response = await invoke(
        apiResource, context.apiAction, request, context.matchResult);
    if (response is! HttpApiResponse) {
      throw new StateError(
          'API actions must return instance of ApiResponse, but ${response} given.');
    } else {
      return next.handle(request, response, context);
    }
  }

  Future<HttpApiResponse> invoke(Object resource, MethodMirror method,
      HttpApiRequest request, MatchResult matchResult) {
    var instanceMirror = reflect(resource); // TODO: cache mirror.

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

/// Resolves API action that match required properties set in the
/// middleware context.
class ApiActionResolverMiddleware implements Middleware {
  @override
  Future<HttpApiResponse> handle(
      HttpApiRequest request, MiddlewareContext context, Next next) async {
    final eq = const SetEquality();
    final Type apiClass = context.matchResult.data;
    final mirror = reflectClass(apiClass); // TODO: cache mirror.
    var methods = mirror.declarations.values
        .where((_) => _ is MethodMirror && _.isRegularMethod && !_.isOperator);
    for (var method in methods) {
      var properties = method.metadata
          .map((_) => _.reflectee)
          .where((_) => _ is ApiActionProperty)
          .toSet();

      if (eq.equals(properties, context.actionProperties)) {
        context.apiAction = method;
      } else {
        continue;
      }
    }

    if (context.apiAction == null) {
      _logger.warning(
          'No matching API action found for properties ${context.actionProperties}');
      return new Future.error(new NotFoundApiError());
    } else {
      return next.handle(request, null, context);
    }
  }
}
