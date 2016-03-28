part of corsac_rpc;

/// Annotation used to define API resources. Should be used on classes.
///
///     @ApiResource(path: '/users')
///     class UsersResource {}
///
/// The [path] property is a parametrized resource path.
class ApiResource {
  /// The URL path of this resource. URL path parameters must be enclosed in
  /// curly braces, e.g. `{id}`.
  final String path;

  /// The group name of this API resource. This does not have any meaning
  /// in the runtime but is only used for documentation purposes.
  /// Examples: `Users`, `Notes`.
  final String group;

  /// Creates new ApiResource annotation.
  const ApiResource({this.path, this.group});

  factory ApiResource.fromClass(Type type) {
    return reflectClass(type)
        .metadata
        .firstWhere((_) => _.reflectee is ApiResource)
        .reflectee;
  }
}

/// Base interface for annotations to be used on methods of ApiResources.
///
/// Action properties directly affect which requests can be handled by particular
/// action. All actions must have at least [ApiMethod] property.
abstract class ApiActionProperty {}

/// Indicates which HTTP method is handled by an action.
///
///     @ApiResource(path: '/users')
///     class UsersResource {
///       @ApiMethod.GET
///       ApiResponse getUsers() {
///         // this method will be invoked for `GET /users` request.
///       }
///     }
class ApiMethod implements ApiActionProperty {
  final String method;
  const ApiMethod(this.method);
  static const GET = const ApiMethod('GET');
  static const POST = const ApiMethod('POST');
  static const PUT = const ApiMethod('PUT');
  static const DELETE = const ApiMethod('DELETE');
  static const OPTIONS = const ApiMethod('OPTIONS');
  static const HEAD = const ApiMethod('HEAD');
  static const PATCH = const ApiMethod('PATCH');

  factory ApiMethod.fromRequest(HttpRequest request) {
    switch (request.method) {
      case 'GET':
        return ApiMethod.GET;
      case 'POST':
        return ApiMethod.POST;
      case 'PUT':
        return ApiMethod.PUT;
      case 'DELETE':
        return ApiMethod.DELETE;
      case 'OPTIONS':
        return ApiMethod.OPTIONS;
      case 'HEAD':
        return ApiMethod.HEAD;
      case 'PATCH':
        return ApiMethod.PATCH;
      default:
        throw new ArgumentError(
            'Unsupported request method "${request.method}".');
    }
  }

  /// Returns set of [ApiMethod]s defined in [resourceClass].
  static Set<ApiMethod> list(Type resourceClass) {
    var mirror = reflectClass(resourceClass);
    var methods =
        mirror.declarations.values.where((_) => _ is MethodMirror).toList();
    var actions = methods.where((method) {
      var annotations =
          method.metadata.where((_) => _.reflectee is ApiMethod).toList();
      if (annotations.length > 1)
        throw new StateError(
            'Resource class method can have only one ApiMethod annotation.');
      return annotations.isNotEmpty;
    });

    return actions
        .map((a) =>
            a.metadata.firstWhere((m) => m.reflectee is ApiMethod).reflectee)
        .toSet();
  }
}

class ApiMessage {
  const ApiMessage();
}

class ApiField {
  final String name;
  final String format;
  final bool required;
  final dynamic defaultValue;
  final String example;
  const ApiField(
      {this.name,
      this.format,
      this.required: false,
      this.defaultValue,
      this.example});
}
