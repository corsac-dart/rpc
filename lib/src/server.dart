part of corsac_rpc;

abstract class ApiServer {
  Router _router;

  String get prefix;

  /// Internet address to bind to.
  InternetAddress get address;

  /// Port to listen on.
  int get port;

  /// API resources handled by this ApiServer.
  Iterable<Type> get apiResources;

  /// Kernel for this ApiServer.
  Kernel get kernel;

  Router get router {
    if (_router == null) {
      _router = new Router();
      for (var apiClass in apiResources) {
        var apiResource = new ApiResource.fromClass(apiClass);
        var apiActions = ApiAction.list(apiClass);
        var httpResource = new HttpResource(
            apiResource.path, apiActions.map((_) => _.method).toSet());

        if (_router.resources.containsKey(httpResource)) {
          throw new StateError(
              'HttpResource already registered for ${httpResource.path}');
        }
        _router.resources[httpResource] = apiClass;
      }
    }

    return _router;
  }

  ApiVersionHandler get apiVersionHandler => new UrlPrefixedApiVerionHandler();

  /// Default handler for error responses.
  ///
  /// Override this to customize the way error responses are handled.
  ApiErrorHandler get errorHandler => (exception, StackTrace stackTrace) {
        _logger.warning(
            'Error handling request: ${exception}', exception, stackTrace);
        if (exception is ApiError) {
          var messages = (exception.errors is List &&
                  exception.errors.isNotEmpty)
              ? exception.errors
              : [exception.message];
          return new ApiResponse.json({'errors': messages},
              statusCode: exception.statusCode);
        } else {
          return new ApiResponse.json({
            'errors': [exception.toString()]
          }, statusCode: HttpStatus.INTERNAL_SERVER_ERROR);
        }
      };

  /// Middleware pipeline for handling requests.
  Pipeline get pipeline => new Pipeline([
        new PrefixMiddleware(prefix),
        new ApiVersionMiddleware(apiVersionHandler),
        new RouterMiddleware(router, kernel),
        new ErrorMiddleware(errorHandler)
      ]);

  /// Starts HTTP server.
  Future run({shared: false}) async {
    final server = await HttpServer.bind(address, port, shared: shared);
    _logger.info('Started server on port ${port}');
    server.listen((r) {
      handleRequest(r);
    }, onError: (e) {
      _logger.warning(e);
    });
  }

  handleRequest(HttpRequest request) {
    var context = new MiddlewareContext(request.requestedUri);
    kernel.execute(() {
      return pipeline.handle(request, context);
    }).catchError((e, stackTrace) {
      _logger.warning('Uncaught error ${e}', e, stackTrace);
      context.response = new ApiResponse.json({
        'errors': [e.toString()]
      }, statusCode: HttpStatus.INTERNAL_SERVER_ERROR);
    }).whenComplete(() {
      request.response.statusCode = context.response.statusCode;
      request.response.headers.contentType = context.response.contentType;
      context.response.headers?.forEach((name, value) {
        request.response.headers.add(name, value);
      });
      if (context.response.body != null) {
        context.response.body.pipe(request.response);
      } else {
        request.response.close();
      }
    });
  }
}
