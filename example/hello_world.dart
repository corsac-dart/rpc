library hello_world;

import 'dart:io';

import 'package:corsac_http_application/corsac_http_application.dart';
import 'package:corsac_router/corsac_router.dart';

class MyApplication extends HttpApplication {
  MyApplication(
      InternetAddress address, int port, String environment, Map parameters)
      : super(address, port, environment, parameters);

  /// This is the only method which must be defined by your app.
  Router get router {
    final router = new Router();
    router.resources[new HttpResource('/hello-world', ['GET'])] =
        new ClassBasedControllerInvoker(HelloWorldController);
    return router;
  }
}

class HelloWorldController extends Object with ControllerResponses {
  @HttpMethod('GET')
  getHelloWorld() {
    return json({'hello': 'world'});
  }
}

main() {
  final app =
      new MyApplication(InternetAddress.LOOPBACK_IP_V4, 8080, 'prod', {});
  app.run();
}
