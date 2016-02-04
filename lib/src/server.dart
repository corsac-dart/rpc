part of corsac_rpc;

/// Default kernel module implementation for [ApiServer].
///
/// This module can be used in most simple scenarios. It is also possible
/// to define your own module or extend this one.
class ApiServerKernelModule extends KernelModule {
  /// List of API resources handled by [ApiServer].
  ///
  /// Classes in this list must be annotated with [ApiResource].
  final Iterable<Type> apiResources;

  ApiServerKernelModule(this.apiResources);

  @override
  Map getServiceConfiguration(String environment) {
    return {
      RouterMiddleware: DI.object()
        ..bindParameter('apiResources', apiResources),
    };
  }
}

/// Base ApiServer class.
class ApiServer {
  final Kernel kernel;

  /// Internet address to bind to. Defaults to `InternetAddress.ANY_IP_V4`.
  InternetAddress address = InternetAddress.ANY_IP_V4;

  /// Port to listen on. Default is `8080`.
  int port = 8080;

  /// Kernel used by this ApiServier.

  Pipeline _pipeline;

  /// Middleware pipeline for handling requests.
  Pipeline get pipeline {
    if (_pipeline == null) {
      _pipeline = new Pipeline([
        kernel.get(RouterMiddleware),
        kernel.get(ApiActionResolverMiddleware),
        kernel.get(AccessControlMiddleware),
        kernel.get(ApiActionInvokerMiddleware)
      ].toSet());
    }

    return _pipeline;
  }

  ApiServer(this.kernel);

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
    var context = new MiddlewareContext(
        request.requestedUri, new ApiMethod.fromRequest(request));

    return kernel.execute(() {
      return pipeline.handle(request, context);
    }).catchError((e, stackTrace) {
      if (e is ApiError) {
        // ApiErrors are "expected" and have all necessary information to
        // render a response.
        var messages = (e.errors is Iterable && e.errors.isNotEmpty)
            ? e.errors
            : [e.message];
        context.response = new ApiResponse.json({'errors': messages},
            statusCode: e.statusCode);
      } else {
        _logger.shout(
            'Unexpected error in `handleRequest` ${e}', e, stackTrace);
        context.response = new ApiResponse.json({
          'errors': ['Internal Server Error.']
        }, statusCode: HttpStatus.INTERNAL_SERVER_ERROR);
      }
    }).whenComplete(() {
      var apiResponse = context.response;

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
