part of corsac_rpc;

abstract class ApiServer {
  Router _router;

  /// Prefix for all API resources.
  ///
  /// If you have defined API resource for path `/users/{id}` then actual URL
  /// that is served by this server will be `{prefix}/users/{id}`. So, if
  /// you set prefix to `/api`, the full URL path would be `/api/users/{id}`.
  ///
  /// This also means that any request's path which does not start with this
  /// prefix will result in 404 response.
  String get prefix => '';

  /// Internet address to bind to. Defaults to `InternetAddress.LOOPBACK_IP_V4`.
  InternetAddress get address => InternetAddress.LOOPBACK_IP_V4;

  /// Port to listen on. Default is `8080`.
  int get port => 8080;

  /// API resources handled by this ApiServer.
  Iterable<Type> get apiResources;

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

  ApiVersionHandler get apiVersionHandler => new UnversionedApiVersionHandler();

  /// Default handler for error responses.
  ///
  /// Override this to customize the way error responses are handled.
  ApiErrorHandler get errorHandler => (exception, StackTrace stackTrace) {
        // TODO: render better 500 error page and update when "debug" is implemented
        _logger.warning(
            'Error handling request: ${exception}', exception, stackTrace);
        if (exception is InternalServerApiError) {
          return new ApiResponse.text(exception.message,
              statusCode: exception.statusCode);
        } else if (exception is ApiError) {
          var messages = (exception.errors is List &&
                  exception.errors.isNotEmpty)
              ? exception.errors
              : [exception.message];
          return new ApiResponse.json({'errors': messages},
              statusCode: exception.statusCode);
        } else {
          return new ApiResponse.text('Internal server error.',
              statusCode: HttpStatus.INTERNAL_SERVER_ERROR);
        }
      };

  /// Middleware pipeline for handling requests.
  Pipeline get pipeline => new Pipeline([
        new ErrorMiddleware(),
        new PrefixMiddleware(prefix),
        new ApiVersionMiddleware(apiVersionHandler),
        new RouterMiddleware(router, kernel.container),
      ]);

  /// Starts HTTP server.
  Future start({shared: false}) async {
    return runZoned(() async {
      final server = await HttpServer.bind(address, port, shared: shared);
      _logger.info('Started server on port ${port}');
      server.listen((r) {
        handleRequest(r);
      }, onError: (e, stackTrace) {
        _logger.warning(e, e, stackTrace);
      });
    }, onError: (e, stackTrace) {
      _logger.shout('Uncaught error: ${e}', e, stackTrace);
    });
  }

  Future handleRequest(HttpRequest request) {
    var context = new MiddlewareContext(request.requestedUri);
    return kernel.execute(() {
      return pipeline.handle(request, context);
    }).catchError((e, stackTrace) {
      _logger.shout('Uncaught error ${e}', e, stackTrace);
      context.exception = new InternalServerApiError(e, stackTrace);
      context.stackTrace = stackTrace;
    }).whenComplete(() {
      var apiResponse = context.hasError
          ? errorHandler(context.exception, context.stackTrace)
          : context.response;

      request.response.statusCode = apiResponse.statusCode;
      request.response.headers.contentType = apiResponse.contentType;
      apiResponse.headers?.forEach((name, value) {
        request.response.headers.add(name, value);
      });
      if (apiResponse.body != null) {
        return apiResponse.body.pipe(request.response);
      } else {
        return request.response.close();
      }
    });
  }
}
