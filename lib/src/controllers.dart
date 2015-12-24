part of corsac_http_application;

/// Invoker of a class-based controller.
///
/// You typically use this when defining your route configuration in HTTP
/// application subclass:
///
///     class MyApplication extends HttpApplication {
///       Router get router {
///         final router = new Router();
///         // Given you defined `UsersController` class somewhere:
///         router.resources.addAll({
///           new HttpResource('/users', ['POST', 'GET']):
///             new ClassBasedControllerInvoker(UsersController),
///         });
///       }
///     }
///
/// Everything else will be taken care of for you by the application.
/// Just make sure to annotate your controller methods with [HttpMethod] so
/// that router can find which method should be used to handle actual request.
class ClassBasedControllerInvoker {
  /// Class of the controller.
  final Type controllerClass;

  /// Creates new invoker associated with particular [controllerClass].
  ClassBasedControllerInvoker(this.controllerClass);

  /// Invokes controller action on [instance] of controller.
  Future invoke(Object instance, HttpRequest request, MatchResult matchResult) {
    var mirror = reflect(instance);
    var method = _findActionMethod(mirror.type, request.method);
    var positionalArguments =
        _resolvePositionalArguments(method, matchResult, request);
    var result =
        mirror.invoke(method.simpleName, positionalArguments).reflectee;

    return (result is Future) ? result : new Future.value(result);
  }

  MethodMirror _findActionMethod(ClassMirror mirror, String httpMethod) {
    var methods = mirror.declarations.values
        .where((d) => d is MethodMirror && d.isRegularMethod);
    return methods.firstWhere((method) {
      var metadata = method.metadata
          .where((item) => item.hasReflectee && item.reflectee is HttpMethod);

      for (var meta in metadata) {
        HttpMethod method = meta.reflectee;
        if (method.method == httpMethod) return true;
      }
      return false;
    });
  }

  List<dynamic> _resolvePositionalArguments(
      MethodMirror mirror, MatchResult matchResult, HttpRequest request) {
    var args = [];
    var list = mirror.parameters.where((p) => !p.isNamed);
    for (var param in list) {
      var name = MirrorSystem.getName(param.simpleName);
      if (param.type.reflectedType == HttpRequest) {
        args.add(request);
      } else if (!param.isOptional) {
        if (matchResult.parameters.containsKey(name)) {
          // TODO: resolve param type too.
          args.add(matchResult.parameters[name]);
        } else {
          throw new StateError(
              "Parameter '${name}' is not present in request.");
        }
      } else {
        if (matchResult.parameters.containsKey(name)) {
          args.add(matchResult.parameters[name]);
        } else if (param.hasDefaultValue) {
          args.add(param.defaultValue.reflectee);
        } else {
          args.add(null);
        }
      }
    }
    return args;
  }
}

/// Annotation to be used in class-based controllers to indicate which
/// controller methods are handling which HTTP methods of the `HttpResource`
/// associated with particular controller.
class HttpMethod {
  /// HTTP method name, like `POST`, `GET`, etc.
  final String method;
  const HttpMethod(this.method);
}

/// Mixin which can be used by class-based controllers.
///
/// Provides convenience helpers for returning common responses. Example:
///
///     class UserController extends Object with ControllerResponses {
///       final UserRepository userRepository;
///
///       UserController(this.userRepository);
///
///       @HttpMethod('GET')
///       getUserAction(HttpRequest request, int userId) {
///         final user = userRepository.findById(userId);
///         // Assuming the User entity uses `corsac_dto`.
///         return json(user.dto);
///       }
///     }
///
abstract class ControllerResponses {
  /// Returns JSON encoded response.
  ///
  /// The [data] parameter must be any object supported by `JSON.encode()`.
  /// You can optionally set response [statusCode], default is 200 OK.
  ControllerResponse json(Object data, {int statusCode: HttpStatus.OK}) =>
      new ControllerResponse.json(data, statusCode: statusCode);
}

/// Convenience helper object which can be returned by class-based
/// controllers instead of modifying `HttpResponse` directly.
///
/// For example, instead of doing this all the time:
///
///     class UserController {
///       @HttpMethod('POST')
///       postUserAction(HttpRequest request) {
///         var user = createUser(); // create the user, persist, etc
///         // Assuming the User entity uses `corsac_dto` library.
///         request.response
///           ..statusCode = HttpStatus.CREATED
///           ..write(JSON.encode(user.dto));
///       }
///     }
///
/// You can leverage this class via [ControllerResponses] mixin:
///
///     class UserController extends Object with ControllerResponses {
///       final UserRepository userRepository;
///
///       UserController(this.userRepository);
///
///       @HttpMethod('POST')
///       postUserAction(HttpRequest request) {
///         final user = createUser(); // create the user, persist, etc
///         // Assuming the User entity uses `corsac_dto`.
///         return json(user.dto, statusCode: HttpStatus.CREATED);
///       }
///     }
///
/// Router middleware which handles responses from controllers has built-in
/// support for when instance of [ControllerResponse] is returned. It will
/// populate actual `HttpResponse` with the data present in controller response.
class ControllerResponse {
  /// HTTP status code of this response.
  final int statusCode;

  /// Content type of this response.
  final ContentType contentType;

  /// Actual content of this response.
  final String content;

  /// Creates new controller response.
  ControllerResponse(this.content, this.contentType,
      {this.statusCode: HttpStatus.OK});

  /// Creates JSON encoded response. This will set ContentType of the response
  /// accordingly.
  ///
  /// You can provide custom [statusCode], by default 200 OK is used.
  ControllerResponse.json(Object data, {int statusCode: HttpStatus.OK})
      : this(JSON.encode(data), ContentType.JSON);

  /// Creates plain text response.
  ///
  /// You can provide custom [statusCode], by default 200 OK is used.
  ControllerResponse.text(String data, {int statusCode: HttpStatus.OK})
      : this(data, ContentType.TEXT);

  /// Creates HTML response. This will set ContentType of the response
  /// accordingly.
  ///
  /// You can provide custom [statusCode], by default 200 OK is used.
  ControllerResponse.html(String data, {int statusCode: HttpStatus.OK})
      : this(data, ContentType.HTML);

  /// Populates actual [response] with the data stored in this instance.
  void apply(HttpResponse response) {
    response
      ..statusCode = statusCode
      ..headers.contentType = contentType
      ..write(content);
  }
}
