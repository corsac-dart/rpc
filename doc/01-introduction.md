# Introduction

Corsac RPC is a lightweight and flexible HTTP API server framework. While
being built on ideas from Dart's `rpc` package it also incorporates some
advanced approaches which makes it easier to extend and scale.

Middleware pipelines are very common concept which is widely used on modern
HTTP applications. This library's **ApiServer** class uses
[corsac-dart/middleware]() component which allows end users to extend it
by adding their own middleware handlers to the server's pipeline.

**ApiServer** also uses [corsac-dart/kernel]() which provides Dependency
Injection container ([corsac-dart/di]()) along with other features.

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
  ApiResponse getUsers() {
    // Fetch all the users and return.
  }
}
```

In order to create an action we just need to declare a public method and
annotate it with `ApiMethod`. One more important note here: all action
methods must return either instance of `ApiResponse` or a future of it
(`Future<ApiResponse>`). For the sake of this example we can return
static list of users:

```dart
@ApiResource(path: '/users')
class UsersResource {
  @ApiMethod.GET
  ApiResponse getUsers() {
    return new ApiResponse.json([
      {'id': 827, 'name': 'Fennec Fox'},
      {'id': 213, 'name': 'Red Fox'},
    ]);
  }
}
```

The `ApiResponse.json` constructor will make sure to set proper
`Content-Type` header for JSON response.

Now we need to register this resource with our **ApiServer**. But first,
we need to create our server by extending from `ApiServer` class:

```dart
class MyApiServer extends ApiServer {
  final Kernel kernel;
  MyApiServer(this.kernel);
}
```

That's it. The only thing we need to provide is how to get an instance
of **Kernel**. In this case we just pass it to the constructor.

> The **Kernel** class is part of **corsac_kernel** package. Please
> refer to [documentation](https://github.com/corsac-dart/kernel) for
> more details.

The **Kernel** gives us two important features:

* Dependency Injection container.
* A way to structure our app using special **KernelModules**.

Corsac RPC provides it's own kernel module which we should use to
achieve our goal:

```dart
import 'package:corsac_kernel/corsac_kernel.dart';
import 'package:corsac_rpc/corsac_rpc.dart';

var serverModule = new ApiServerKernelModule([UsersResource]);
var kernel = await Kernel.build('prod', {}, [serverModule]);
var server = new MyApiServer(kernel);
server.start();
```

First we create instance of `ApiServerKernelModule` and pass
our `UsersResource` type to the constructor. Then we create the
kernel itself and register `serverModule` with it. Finally we
create an instance of our API server with the kernel we have and
start the server.

> By default `ApiServer` listens on port `8080` but this can be
> customized, of course.

If we navigate to `http://localhost:8080/users` in the browser we
should see our hardcoded list of users.