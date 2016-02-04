# Additional middlewares

The `corsac_rpc` package provides some extra middlewares which can be used
when needed. To use them one just need to import `corsac_rpc.middleware`
library:

```dart
import 'package:corsac_rpc/middleware.dart';
```

To register new middleware just add it to `beforeHandlers` of
`ApiServer.pipeline`:

```dart
class MyApiServer {
  @override
  final Kernel kernel;
  MyApiServer(this.kernel) {
    pipeline.beforeHandlers.add(new PrefixMiddleware('/api'));
  }
}
```

## List of provided middlewares

* [PrefixMiddleware](doc/04.1-prefix-middleware.md) - can be used in case all
  URLs are prefixed with some static value, e.g. `/api/users`. This middleware
  will remove the prefix, so that you don't have to add it in all your
  **ApiResources** (like `@ApiResource(path: '/api/users')`) which helps
  to keep things a bit cleaner.
* [UrlVersionMiddleware](doc/04.2-url-version-middleware.md) - can be used
  for versioned APIs which have their version specified in the URL, e.g.
  `/v1/users`.
* [AcceptHeaderVersionMiddleware](doc/04.3-accept-header-version-middleware.md) -
  can be used for versioned APIs which have their version specified in the
  `Accept` HTTP header, e.g. `application/vnd.foo.com+json; version=5`.
