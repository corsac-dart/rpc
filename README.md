# Corsac RPC

REST-style API server inspired by Dart's __rpc__ package.

Corsac RPC uses standard `HttpServer` from `dart:io` as well as
some of the __corsac-dart__ components including
[corsac-dart/kernel](https://github.com/corsac-dart/kernel),
[corsac-dart/router](https://github.com/corsac-dart/router) and
[corsac-dart/middleware](https://github.com/corsac-dart/middleware).

## Status

This library is a work-in-progress so breaking changes may occur without notice.

## Usage

Here is simplest "Hello World" implementation:

```dart
// file: main.dart
library hello_world;

import 'package:corsac_rpc/corsac_rpc.dart';

// Create your own subclass of `ApiServer`
class HelloWorldApiServer extends ApiServer {
  final Kernel kernel;
  HelloWorldApiServer(this.kernel);

  @override
  Iterable<Type> get apiResources => [HelloWorldResource];
}

// Define your API resource(s)
@ApiResource(path: '/hello-world')
class HelloWorldResource {
  @ApiAction(method: 'GET')
  ApiResponse sayHello() => new ApiResponse.json({'message': 'Hello world!'});
}

// Start the server
void main() async {
  final kernel = await Kernel.build('prod', {}, []);
  final server = new HelloWorldServer(kernel);
  server.start();
}
```

## Main concepts

1. `ApiResource` handles a particular HTTP route (path). ApiResources are
  very similar to REST HTTP resource but also have some differences. Each
  ApiResource defines a set of `ApiAction`s.
2. `ApiAction` is responsible for handling incoming request with particular
  HTTP method. That is, the action from the "HelloWorld" example will be
  triggered when the server receives HTTP request for `GET /hello-world`.
  Important feature of ApiActions is that they can be versioned (see
  details below).
3. `ApiServer` is the main class which starts HttpServer and handles
  requests.
4. `ApiResponse` is an intermediate object returned from ApiActions holding
  all necessary information to be populated in the actual `HttpResponse`
  returned to the client.

## Api Versioning

Important feature of `ApiServer` is that all resources and actions can be
versioned. By default, though, `ApiServer` is configured to be "unversioned".

There are two common strategies for versioning REST APIs:

1. Using URL prefix. E.g.: `/v1/hello-world`
2. Using Accept header, which also has two variations:
  1. `Accept: application/vnd.foo.com.v1+json`
  2. `Accept: application/vnd.foo.com+json; version=1`

Both options are supported by this library. You are also free to implement
your own.

To start using URL-prefixed versioning just override `apiVersionHandler`
getter on your subclass of `ApiServer`:

```dart
class HelloWorldApiServer extends ApiServer {
  // The rest of the implementation is omitted
  ApiVersionHandler get apiVersionHandler
    => new UrlPrefixedApiVersionHandler();
}
```

Enabling this strategy means that actual URL for the `HelloWorldResource`
will look like `GET /v1/hello-world`. However there is no need to modify
resource's path, version prefix will be stripped from the url by the server
automatically before passing it to the routing component.

There is one thing though that needs to be updated on the ApiResource.
Since we require versions now, we must specify which versions are handled by
`ApiAction`s of our resource:

```dart
@ApiResource(path: '/hello-world')
class HelloWorldResource {
  @ApiAction(method: 'GET', versions: const ['1'])
  ApiResponse sayHello()
    => new ApiResponse.json({'message': 'Hello world!'});
}
```

Now our resource only supports version '1', so any other requested version
(or no version) will result in 404 HTTP response.

It is important to note that since `ApiAction`s are versioned, this means
one can define multiple actions handling the same HTTP method, however
versions must not intersect between those actions. Following is a valid
example:

```dart
@ApiResource(path: '/hello-world')
class HelloWorldResource {
  @ApiAction(method: 'GET', versions: const ['1'])
  ApiResponse sayHelloDeprecated()
    => new ApiResponse.json({'message': 'Hello world!'});

  @ApiAction(method: 'GET', versions: const ['2', '3'])
  ApiResponse sayHello()
    => new ApiResponse.json({'message': 'Hello WORLD!'});
}
```

## Resource parameters

ApiResources can be parametrized. This is based completely on the
[corsac-dart/router](https://github.com/corsac-dart/router) functionality.

Resource parameters will be automatically promoted to action method
arguments if present:


```dart
@ApiResource(path: '/greet/{name}')
class GreetingResource {
  @ApiAction(method: 'GET', versions: const ['1'])
  ApiResponse great(String name)
    => new ApiResponse.json({'message': 'Hello, ${name}!'});
}
```

In some cases parameter can be formatted according to it's type before
passing to the resource action method. Currently only `int` and `DateTime`
types are supported:

```dart
@ApiResource(path: '/users/{id}/history/{date}')
class UserHistoryResource {
  @ApiAction(method: 'GET', versions: const ['1'])
  ApiResponse great(int id, DateTime date) {
    // Routing component will attempt to do `int.parse()` on the
    // `id` parameter, if successful, result will be passed here.
    // The same with the `date` parameter.
  }
}
```
