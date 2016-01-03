# Corsac HTTP application

Provides "officially" (Corsac-style) flavored abstraction for implementing
HTTP server applications.

This library is built on top of standard `HttpServer` from `dart:io` leveraging
other Corsac components like
[corsac_kernel](https://github.com/corsac-dart/kernel),
[corsac_router](https://github.com/corsac-dart/router) and
[corsac_middleware](https://github.com/corsac-dart/middleware).

# Status

This library is a work-in-progress so breaking changes may occur without notice.

# Installation

Via Git dependency in your pubspec.yaml:

```yaml
dependencies:
  corsac_http_application:
    git: https://github.com/corsac-dart/http-application.git
```

Import:

```dart
import 'package:corsac_http_application/corsac_http_application.dart';
```

Pub package will be added as soon as API is stable enough.

# Usage

Simplest example. Define your subclass of `HttpApplication`:

```dart
// file: lib/my_app.dart
library my_app;

import 'package:corsac_http_application/corsac_http_application.dart';

part 'src/controllers.dart'; // see implementation below

class MyApplication extends HttpApplication {
  MyApplication(InternetAddress address, int port, String environment,
    Map parameters) : super(address, port, environment, parameters);

  /// This is the only method which must be defined by your app.
  Router get router {
    final router = new Router();
    router.resources[new HttpResource('/hello-world', ['GET'])] =
      new ClassBasedControllerInvoker(HelloWorldController);
    return router;
  }
}
```

Create controller:

```dart
// file: lib/src/controllers.dart
part of my_app;

class HelloWorldController extends Object with ControllerResponses {
  @HttpMethod('GET')
  getHelloWorld() {
    return json({'hello': 'world'});
  }
}
```

Implement your `main()` function:

```dart

import 'package:my_app/my_app.dart';

main() {
  var app = new MyApplication(InternetAddress.LOOPBACK_IP_V4, 8080, 'prod', {});
  app.run();
}
```

That's it.

More documentation to be added soon.
