# Corsac RPC

REST-style API server inspired by Dart's __rpc__ package.

Corsac RPC uses standard `HttpServer` from `dart:io` as well as
some of the __corsac-dart__ components including
[corsac-dart/kernel](https://github.com/corsac-dart/kernel),
[corsac-dart/router](https://github.com/corsac-dart/router).

## Status

This library is a work-in-progress so breaking changes may occur without notice.

## Usage

Here is simplest "Hello World" implementation:

```dart
// file: main.dart
library hello_world;

import 'package:corsac_rpc/corsac_rpc.dart';
import 'package:logging/logging.dart';

@ApiResource(path: '/hello-world/{name}')
class HelloWorldResource {
  @ApiMethod.GET
  HttpApiResponse getHelloWorld(String name) {
    return new HttpApiResponse.json({'myNameIs': name});
  }
}

main() async {
  final kernel = await Kernel.build('prod', {}, []);
  final app = new ApiServer(kernel, [HelloWorldResource]);
  app.start();
}
```

## Documentation

1. [Introduction](doc/01-introduction.md)
2. API Resources
3. Middleware pipeline
4. Additional middlewares:
  1. PrefixMiddleware
  2. VersionMiddleware
