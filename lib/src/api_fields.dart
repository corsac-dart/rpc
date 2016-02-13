part of corsac_rpc;

abstract class ApiFieldResolver {
  Object resolve(ParameterMirror mirror, HttpApiRequest request,
      Map<String, dynamic> attributes);

  factory ApiFieldResolver(mirror) {
    if (mirror is ParameterMirror) {
      if (!mirror.type.hasReflectedType) {
        throw new StateError('Action parameters must be type-annotated.');
      }

      if (mirror.isNamed) {
        return const QueryApiFieldResolver();
      } else if (mirror.type.reflectedType == HttpApiRequest) {
        return const HttpApiRequestFieldResolver();
      } else if (_isApiMessage(mirror)) {
        return const ApiMessageFieldResolver();
      } else {
        return const DefaultApiFieldResolver();
      }
    }
  }

  static bool _isApiMessage(ParameterMirror mirror) {
    return mirror.type.metadata
        .map((_) => _.reflectee)
        .contains(const ApiMessage());
  }

  static ApiField getMetadata(TypeMirror mirror) {
    return mirror.metadata
        .firstWhere((_) => _.reflectee is ApiField, orElse: () => null)
        ?.reflectee;
  }

  static dynamic parse(dynamic value, TypeMirror type) {
    if (type.reflectedType == int) {
      return (value is int) ? value : int.parse(value);
    } else if (type.reflectedType == DateTime) {
      return DateTime.parse(value);
    } else if (type.reflectedType == String) {
      return value.toString();
    } else if (type.reflectedType == bool) {
      return (value is bool) ? value : value == 'true';
    } else {
      // TODO: handle more types (all primitives, Uri, ...)
      throw new FormatException('Parameter type not supported.');
    }
  }
}

class HttpApiRequestFieldResolver implements ApiFieldResolver {
  const HttpApiRequestFieldResolver();

  @override
  Object resolve(ParameterMirror mirror, HttpApiRequest request,
      Map<String, dynamic> attributes) {
    return request;
  }
}

class ApiMessageFieldResolver implements ApiFieldResolver {
  const ApiMessageFieldResolver();

  @override
  Object resolve(ParameterMirror mirror, HttpApiRequest request,
      Map<String, dynamic> attributes) {
    ClassMirror classMirror = mirror.type;
    InstanceMirror instanceMirror = classMirror.newInstance(new Symbol(''), []);

    for (var member in _collectFields(classMirror)) {
      var memberName = MirrorSystem.getName(member.simpleName);
      ApiField field = member.metadata
          .map((_) => _.reflectee)
          .firstWhere((_) => _ is ApiField, orElse: () => const ApiField());

      String attrName = field.name ?? memberName;
      var value = attributes[attrName];
      if (value == null && field.required) {
        throw new BadRequestApiError(['Missing required field ${attrName}']);
      } else if (value != null) {
        value = ApiFieldResolver.parse(value, member.type);
        instanceMirror.setField(member.simpleName, value);
      }
    }
    return instanceMirror.reflectee;
  }

  List<VariableMirror> _collectFields(ClassMirror mirror) {
    List<VariableMirror> fields = mirror.declarations.values
        .where((_) => _ is VariableMirror)
        .map((_) => _ as VariableMirror)
        .toList();

    if (mirror.superclass.reflectedType != Object) {
      var superclassFields = _collectFields(mirror.superclass);
      fields.addAll(superclassFields);
    }

    return fields;
  }
}

class QueryApiFieldResolver implements ApiFieldResolver {
  const QueryApiFieldResolver();

  @override
  Object resolve(ParameterMirror mirror, HttpApiRequest request,
      Map<String, dynamic> attributes) {
    var name = MirrorSystem.getName(mirror.simpleName);
    if (request.uri.queryParameters.containsKey(name)) {
      var value = request.uri.queryParameters[name];
      return ApiFieldResolver.parse(value, mirror.type);
    }

    return null;
  }
}

class DefaultApiFieldResolver implements ApiFieldResolver {
  const DefaultApiFieldResolver();

  @override
  Object resolve(ParameterMirror mirror, HttpApiRequest request,
      Map<String, dynamic> attributes) {
    var name = MirrorSystem.getName(mirror.simpleName);
    if (attributes.containsKey(name)) {
      var value = attributes[name];
      return ApiFieldResolver.parse(value, mirror.type);
    } else {
      throw new StateError('No resource parameter with name ${name} found.');
    }
  }
}
