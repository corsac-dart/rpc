part of corsac_rpc;

/// Default kernel module implementation for [ApiServer].
///
/// You can either extend this class or use it directly.
class ApiServerKernelModule extends KernelModule {
  /// List of API resources handled by [ApiServer].
  ///
  /// Classes in this list must be annotated with [ApiResource].
  Iterable<Type> apiResources = [];

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
    var apiRequest = new HttpApiRequest.fromHttpRequest(request);
    var context = new MiddlewareContext(
        request.requestedUri, new ApiMethod.fromRequest(request));
    HttpApiResponse apiResponse;

    return kernel.execute(() {
      return pipeline.handle(apiRequest, context);
    }).then((HttpApiResponse response) {
      apiResponse = response;
    }, onError: (e, stackTrace) {
      if (e is ApiError) {
        // ApiErrors are "expected" and have all necessary information to
        // render a response.
        var messages = (e.errors is Iterable && e.errors.isNotEmpty)
            ? e.errors
            : [e.message];
        apiResponse = new HttpApiResponse.json({'errors': messages},
            statusCode: e.statusCode);
      } else {
        _logger.shout(
            'Unexpected error in `handleRequest` ${e}', e, stackTrace);
        apiResponse = new HttpApiResponse.json({
          'errors': ['Internal Server Error.']
        }, statusCode: HttpStatus.INTERNAL_SERVER_ERROR);
      }
    }).whenComplete(() {
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
