part of corsac_rpc;

abstract class ApiFieldResolver {
  Object resolve(
      ParameterMirror mirror, HttpApiRequest request, MatchResult matchResult);

  factory ApiFieldResolver(mirror) {
    if (mirror is ParameterMirror) {
      if (mirror.isNamed) {
        return const QueryApiFieldResolver();
      } else if (mirror.type.reflectedType == HttpApiRequest) {
        return const HttpApiRequestFieldResolver();
      } else {
        return const ResourceParameterApiFieldResolver();
      }
    }
  }

  static ApiField getMetadata(TypeMirror mirror) {
    return mirror.metadata
        .firstWhere((_) => _.reflectee is ApiField, orElse: () => null)
        ?.reflectee;
  }

  static dynamic parse(dynamic value, TypeMirror type) {
    if (type.reflectedType == int) {
      return int.parse(value);
    } else if (type.reflectedType == DateTime) {
      return DateTime.parse(value);
    } else if (type.reflectedType == String) {
      return value;
    } else {
      // TODO: handle more types (all primitives, Uri, ...)
      throw new FormatException('Query parameter type not supported.');
    }
  }
}

class HttpApiRequestFieldResolver implements ApiFieldResolver {
  const HttpApiRequestFieldResolver();

  @override
  Object resolve(
      ParameterMirror mirror, HttpApiRequest request, MatchResult matchResult) {
    return request;
  }
}

class ApiMessageFieldResolver implements ApiFieldResolver {
  const ApiMessageFieldResolver();

  @override
  Object resolve(
      ParameterMirror mirror, HttpApiRequest request, MatchResult matchResult) {
    throw 'Not implemented';
  }
}

class QueryApiFieldResolver implements ApiFieldResolver {
  const QueryApiFieldResolver();

  @override
  Object resolve(
      ParameterMirror mirror, HttpApiRequest request, MatchResult matchResult) {
    var name = MirrorSystem.getName(mirror.simpleName);
    if (request.uri.queryParameters.containsKey(name)) {
      var value = request.uri.queryParameters[name];
      return ApiFieldResolver.parse(value, mirror.type);
    }

    return null;
  }
}

class ResourceParameterApiFieldResolver implements ApiFieldResolver {
  const ResourceParameterApiFieldResolver();

  @override
  Object resolve(
      ParameterMirror mirror, HttpApiRequest request, MatchResult matchResult) {
    var name = MirrorSystem.getName(mirror.simpleName);
    if (matchResult.parameters.containsKey(name)) {
      var value = matchResult.parameters[name];
      return ApiFieldResolver.parse(value, mirror.type);
    } else {
      throw new StateError('No resource parameter with name ${name} found.');
    }
  }
}
