part of corsac_rpc;

class ApiResource {
  final String path;

  const ApiResource({this.path});

  factory ApiResource.fromClass(Type type) {
    return reflectClass(type)
        .metadata
        .firstWhere((_) => _.reflectee is ApiResource)
        .reflectee;
  }
}

class ApiAction {
  final String method;
  final List<Object> versions;

  const ApiAction({this.method, this.versions});

  static Iterable<ApiAction> list(Type resourceClass) {
    var mirror = reflectClass(resourceClass);
    var methods =
        mirror.declarations.values.where((_) => _ is MethodMirror).toList();
    var actions = methods.where((method) {
      var annotations =
          method.metadata.where((_) => _.reflectee is ApiAction).toList();
      if (annotations.length > 1) throw new StateError(
          'Resource class method can have only one ApiAction annotation.');
      return annotations.isNotEmpty;
    });

    return actions
        .map((a) =>
            a.metadata.firstWhere((m) => m.reflectee is ApiAction).reflectee)
        .toList();
  }

  static ApiAction match(Type resourceClass, String method, Object version) {
    try {
      final ucMethod = method.toUpperCase();
      final list = ApiAction.list(resourceClass);
      if (version == '*') {
        return list
            .where(
                (_) => _.method.toUpperCase() == ucMethod && _.versions == null)
            .single;
      } else {
        return list
            .where((_) => _.method.toUpperCase() == ucMethod &&
                (_.versions is Iterable && _.versions.contains(version)))
            .single;
      }
    } on StateError {
      return null;
    }
  }
}

class ApiMessage {
  const ApiMessage();
}

class ApiField {
  final String format;
  final bool required;
  final dynamic defaultValue;
  const ApiField({this.format, this.required: false, this.defaultValue});
}
