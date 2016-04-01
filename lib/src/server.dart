part of corsac_rpc;

/// Base ApiServer class.
class ApiServer {
  /// Kernel used by this ApiServier.
  final Kernel kernel;

  /// The list of API resource types.
  final Iterable<Type> apiResources;

  /// The name of this API server.
  final String name;

  /// Internet address to bind to. Defaults to `InternetAddress.ANY_IP_V4`.
  InternetAddress address = InternetAddress.ANY_IP_V4;

  /// Port to listen on. Default is `8080`.
  int port = 8080;

  Pipeline _pipeline;

  /// Middleware pipeline for handling requests.
  Pipeline get pipeline {
    if (_pipeline == null) {
      _pipeline = new Pipeline([
        kernel.get(RouterMiddleware),
        kernel.get(ActionResolverMiddleware),
        kernel.get(AccessControlMiddleware),
        kernel.get(ContentDecoderMiddleware),
        kernel.get(ActionInvokerMiddleware)
      ].toSet());
    }

    return _pipeline;
  }

  ApiServer(this.kernel, this.apiResources, {this.name: 'api_server'}) {
    kernel.container.set('apiResources', apiResources);
    kernel.container.set(RouterMiddleware,
        DI.object()..bindParameter('apiResources', DI.get('apiResources')));
  }

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

  /// Handles provided `request`.
  ///
  /// Since the `request` parameter is a standard `HttpRequest` from `dart:io`
  /// one can use this method with any instance of `HttpServer`.
  /// Optional `context` parameter provides access to internal details of
  /// request handling and normally should not be used, but in some use cases
  /// (like generating API documentation) may be useful.
  Future handleRequest(HttpRequest request, {MiddlewareContext context}) {
    var apiRequest = new HttpApiRequest.fromHttpRequest(request);
    context ??= new MiddlewareContext(
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

  /// Sets decoder for particular [contentType].
  ///
  /// This will override existing decoder if it was set previously.
  void putContentDecoder(ContentType contentType, ContentDecoder decoder) {
    ContentDecoderMiddleware middleware = kernel.get(ContentDecoderMiddleware);
    middleware.decoders[contentType] = decoder;
  }
}
