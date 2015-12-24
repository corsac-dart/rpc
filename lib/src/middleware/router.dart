part of corsac_http_application;

class RouterMiddleware implements Middleware {
  final Router router;
  final Kernel kernel;

  RouterMiddleware(this.router, this.kernel);

  @override
  Future handle(HttpRequest request, Next next) async {
    var matchResult = router.match(request.uri, request.method);
    if (matchResult.hasMatch) {
      final ClassBasedControllerInvoker invoker = matchResult.data;
      final controller = kernel.container.get(invoker.controllerClass);
      var result = await invoker.invoke(controller, request, matchResult);
      if (result is ControllerResponse) {
        result.apply(request.response);
      } else if (result is String) {
        request.response.write(result);
      } else if (result != null) {
        throw new StateError(
            'Controller returned response of type which can not be processed: ${result.runtimeType}. Only String and ControllerResponse are supported.');
      }
    } else {
      request.response.statusCode = HttpStatus.NOT_FOUND;
    }

    await next.handle(request);
  }
}
