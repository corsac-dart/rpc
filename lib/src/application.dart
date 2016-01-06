part of corsac_http_application;

abstract class HttpApplication {
  final InternetAddress address;
  final int port;
  final String environment;
  final Map<String, dynamic> parameters;

  HttpApplication(this.address, this.port, this.environment, this.parameters);

  Router get router;

  Future<Kernel> createKernel() => Kernel.build(environment, parameters, []);

  Pipeline createPipeline(Kernel kernel) {
    return new Pipeline([new RouterMiddleware(router, kernel)]);
  }

  Future run() async {
    final server = await HttpServer.bind(address, port);
    print('Started server on port ${port}'); // TODO replace with logger
    await for (final HttpRequest request in server) {
      await handleRequest(request);
    }
  }

  Future handleRequest(HttpRequest request) async {
    try {
      final kernel = await createKernel();
      final pipeline = createPipeline(kernel);
      await pipeline.handle(request);
    } catch (e, stackTrace) {
      print(e); // TODO replace with logger
      print(stackTrace);
      request.response.statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
      request.response.write(e);
    } finally {
      request.response.close();
    }
  }
}
