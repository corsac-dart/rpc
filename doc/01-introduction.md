# Introduction

Corsac RPC is a lightweight and flexible HTTP API server framework. While
being built on ideas from Dart's `rpc` package it also incorporates some
advanced approaches which makes it easier to extend and scale.

Middleware pipelines are very common concept which is widely used on modern
HTTP applications. This library's **ApiServer** class uses
it's own middleware component which allows end users to extend it
by adding their own middleware handlers to the server's pipeline.

**ApiServer** also uses [corsac-dart/kernel](https://github.com/corsac-dart/kernel) which provides Dependency
Injection container ([corsac-dart/di](https://github.com/corsac-dart/di)) along with other features.

Each **ApiServer** application defines a set of **ApiResources** which
are similar to traditional concept of **routes** but have different
semantics and structure.

Idea of **ApiResource** is loosely based on a concept of REST HTTP
resource.

**ApiResource** is identified by a URL path. Following examples are all
different resources:

```sh
/users             # a user collection resource
/users/827         # resource for a user with ID 827
/users/101         # resource for a user with ID 101
/users/827/profile # profile resource for a user with ID 827
```

Each resource can define a set of actions it supports. Actions in the
REST API world are just standard HTTP methods: `GET`, `POST`, `PUT`,
`DELETE`, etc.

So `GET /users` would mean we want to fetch a list of all users.

> Designing RESTful APIs is a big topic in itself and above examples
> are only to introduce readers to the basics.
> Please refer to resources about designing RESTful APIs in
> the Internet for more details on this subject. Like
> [this one](https://restful-api-design.readthedocs.org/en/latest/intro.html).

In order to create an **ApiResource** one just need to create a new
class and annotate it with `ApiResource`:

```dart
@ApiResource(path: '/users')
class UsersResource {}
```

This class will be responsible for handling all the HTTP requests to
`/users` path. One can think of it as a traditional **Controller** in
the MVC-style architecture.

Now, we have our ApiResource, but we haven't defined any actions. Let's
fix this:

```dart
@ApiResource(path: '/users')
class UsersResource {
  @ApiMethod.GET
  HttpApiResponse getUsers() {
    // Fetch all the users and return.
  }
}
```

In order to create an action we just need to declare a public method and
annotate it with `ApiMethod`. One more important note here: all action
methods must return either instance of `HttpApiResponse` or a future of it
(`Future<HttpApiResponse>`). For the sake of this example we can return
static list of users:

```dart
@ApiResource(path: '/users')
class UsersResource {
  @ApiMethod.GET
  ApiResponse getUsers() {
    return new HttpApiResponse.json([
      {'id': 827, 'name': 'Fennec Fox'},
      {'id': 125, 'name': 'Red Fox'},
      {'id': 23, 'name': 'Corsac Fox'},
    ]);
  }
}
```

The `HttpApiResponse.json` constructor will make sure to set proper
`Content-Type` header for JSON response.

Now we need to register this resource with our **ApiServer**. We also need to
provide an instance of **Kernel** since API server uses it to handle requests
in an isolated scope.

> The **Kernel** class is part of **corsac_kernel** package. Please
> refer to [documentation](https://github.com/corsac-dart/kernel) for
> more details.

Starting an HTTP server is just a few lines of code:

```dart
import 'package:corsac_rpc/corsac_rpc.dart';

var kernel = await Kernel.build('prod', {}, []);
var server = new ApiServer(kernel, [UsersResource]);
server.start();
```

First we create the kernel itself and register. Then we
create an instance of our API server with the kernel we have and
start the server.

> By default `ApiServer` listens on port `8080` but this can be
> customized, of course.

If we navigate to `http://localhost:8080/users` in the browser we
should see our hardcoded list of users.
