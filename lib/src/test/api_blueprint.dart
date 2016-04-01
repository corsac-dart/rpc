part of corsac_rpc.test;

List<String> _readDocComment(SourceLocation location, String packageRoot) {
  var relativePath = location.sourceUri.pathSegments.toList();
  relativePath[0] = 'lib';
  var path = [packageRoot, relativePath.join(Platform.pathSeparator)]
      .join(Platform.pathSeparator);
  var res = new File(path);
  var lines = res.readAsLinesSync().take(location.line).toList();
  List<String> docLines = [];
  while (true) {
    var l = lines.removeLast();
    if (l.trim().isEmpty) break;
    if (l.trim().startsWith('@')) {
      continue;
    } else if (l.trim().startsWith('// ')) {
      break;
    } else if (l.trim().startsWith('///')) {
      docLines.add(l.trim());
      break;
    }
  }
  if (docLines.isNotEmpty) {
    while (true) {
      var l = lines.removeLast();
      if (l.trim().startsWith('///')) {
        docLines.add(l.trim());
      } else {
        break;
      }
    }
  }
  docLines =
      docLines.reversed.map((_) => _.replaceFirst('///', '').trim()).toList();

  if (docLines.isEmpty) {
    return ['', null];
  } else {
    var header = docLines.removeAt(0);
    var body = docLines.join(' ').trim();
    return [header, body];
  }
}

class _ApiGroupBlock {
  final String name;
  final String body;

  String get sanitizedName => name.replaceAll(' ', '-').toLowerCase();

  _ApiGroupBlock(String name, {this.body: ''}) : name = name ?? 'Other';

  factory _ApiGroupBlock.build(Type resource) {
    ApiResource res = reflectType(resource)
        .metadata
        .firstWhere((_) => _.reflectee is ApiResource)
        .reflectee;
    return new _ApiGroupBlock(res.group);
  }

  @override
  String toString() => '# Group ${name}\n\n${body}\n\n';

  void writeFile(String path) {
    var filename =
        [path, "05_${sanitizedName}_01.apib"].join(Platform.pathSeparator);
    new File(filename).writeAsStringSync(this.toString());
  }
}

class _ApiRouteBlock {
  final _ApiGroupBlock group;
  final String name;
  final String route;
  final String description;
  final List<_ApiParam> parameters;

  String get sanitizedRoute => route
      .replaceFirst('/', '')
      .replaceAll('/', '-')
      .replaceAll('{', '')
      .replaceAll('}', '');

  _ApiRouteBlock(
      this.group, this.name, this.route, this.description, this.parameters);

  static _ApiRouteBlock build(String packageRoot, Type resource,
      _ApiGroupBlock group, MiddlewareContext context) {
    ApiResource res = reflectType(resource)
        .metadata
        .firstWhere((_) => _.reflectee is ApiResource)
        .reflectee;
    var doc = _readDocComment(reflectType(resource).location, packageRoot);
    var paramNames = context.matchResult.parameters.keys;
    List<_ApiParam> apiParams = [];
    for (var methodParam in context.apiAction.parameters) {
      var name = MirrorSystem.getName(methodParam.simpleName);
      if (!paramNames.contains(name)) continue;

      var type = methodParam.type.reflectedType.toString();
      apiParams.add(new _ApiParam(name, type, true, null, null));
    }
    return new _ApiRouteBlock(group, doc.first, res.path, doc.last, apiParams);
  }

  @override
  String toString() {
    var buf = new StringBuffer('## $name [${route}]\n\n');
    if (description is String) {
      buf..writeln(description)..writeln();
    }
    if (parameters is Iterable && parameters.isNotEmpty) {
      buf..writeln('+ Parameters')..writeln();
      for (var param in parameters) {
        buf.writeln(param);
      }
      buf.writeln();
    }
    return buf.toString();
  }

  void writeFile(String path) {
    var sanitizedGroup = group.sanitizedName;
    var sanitizedRes = route
        .replaceFirst('/', '')
        .replaceAll('/', '-')
        .replaceAll('{', '')
        .replaceAll('}', '');
    var filename = '05_${sanitizedGroup}_05_${sanitizedRes}_01.apib';
    var filePath = [path, filename].join(Platform.pathSeparator);

    new File(filePath).writeAsStringSync(this.toString());
  }
}

class _ApiParam {
  final String name;
  final String type;
  final bool required;
  final String description;
  final String example;

  _ApiParam(
      this.name, this.type, this.required, this.description, this.example);

  @override
  String toString() {
    var buf = new StringBuffer('    + ${name}:');
    if (example is String && example.isNotEmpty) buf.write(' `${example}`');
    if (required || type is String) {
      buf.write(' (');
      var items = [];
      if (required) items.add('required');
      if (type is String) items.add(type);
      buf.write(items.join(',') + ')');
    }
    if (description is String) {
      buf.write(' - ${description}');
    }
    return buf.toString();
  }
}

class _ApiActionBlock {
  final String name;
  final String method;
  final String description;
  final _ApiRouteBlock route;

  _ApiActionBlock(this.name, this.method, this.description, this.route);

  static _ApiActionBlock build(String packageRoot, _ApiRouteBlock route,
      MiddlewareContext context, HttpRequestMock request) {
    var doc = _readDocComment(context.apiAction.location, packageRoot);
    return new _ApiActionBlock(doc.first, request.method, doc.last, route);
  }

  @override
  toString() {
    var buf = new StringBuffer('### ${name} [${method.toUpperCase()}]\n\n');
    if (description is String && description.isNotEmpty) {
      buf..writeln(description)..writeln();
    }
    return buf.toString();
  }

  void writeFile(String path) {
    var sanitizedGroup = route.group.sanitizedName;
    var sanitizedRes = route.sanitizedRoute;
    var sanitizedMethod = method.toLowerCase();
    var filename =
        '05_${sanitizedGroup}_05_${sanitizedRes}_05_${sanitizedMethod}_000.apib';
    var filePath = [path, filename].join(Platform.pathSeparator);

    new File(filePath).writeAsStringSync(this.toString());
  }
}

class _ApiRequestBlock {
  final HttpRequestMock request;
  final _ApiActionBlock action;

  _ApiRequestBlock(this.request, this.action);

  factory _ApiRequestBlock.build(
      HttpRequestMock request, _ApiActionBlock action) {
    return new _ApiRequestBlock(request, action);
  }

  @override
  toString() {
    var buf = new StringBuffer();
    if (request.body is String && request.body.isNotEmpty) {
      var contentType = request.headers.value('content-type') ?? '';
      buf..write('+ Request');
      if (contentType.isNotEmpty) buf.write(' (${contentType})');
      buf..writeln()..writeln();

      buf.writeln('    + Body');
      request.body
          .split('\n')
          .map((_) => '            ${_}')
          .forEach(buf.writeln);
      buf.writeln();
    }

    var responseContentType = request.responseMock.headers['content-type'];
    buf
      ..writeln(
          '+ Response ${request.responseMock.statusCode} ($responseContentType)')
      ..writeln();
    if (request.responseMock.body is String &&
        request.responseMock.body.isNotEmpty) {
      buf..writeln('    + Body')..writeln();
      request.responseMock.body
          .split('\n')
          .map((_) => '            ${_}')
          .forEach(buf.writeln);
      buf.writeln();
    }

    return buf.toString();
  }

  void writeFile(String path) {
    var sanitizedGroup = action.route.group.sanitizedName;
    var sanitizedRes = action.route.sanitizedRoute;
    var sanitizedMethod = request.method.toLowerCase();
    var status = request.response.statusCode;
    var filename =
        '05_${sanitizedGroup}_05_${sanitizedRes}_05_${sanitizedMethod}_${status}.apib';
    var filePath = [path, filename].join(Platform.pathSeparator);

    new File(filePath).writeAsStringSync(this.toString());
  }
}

class _ApiBlueprint {
  Future generate(String packageRoot, MiddlewareContext context,
      HttpRequestMock request, ApiServer server) {
    if (context.matchResult == null) return new Future.value();
    if (!context.matchResult.hasMatch) return new Future.value();

    var subpath = Platform.environment['CORSAC_RPC_API_BLUEPRINT_PATH'];
    if (subpath == null) return new Future.value();

    Type type = context.matchResult.data;

    checkPubspecExists(packageRoot);

    var versionProp = context.actionProperties
        .firstWhere((_) => _ is ApiVersion, orElse: () => null);
    var version;
    if (versionProp is ApiVersion) {
      version = versionProp.version.startsWith('v')
          ? versionProp.version
          : 'v${versionProp.version}';
    } else {
      version = 'unversioned';
    }
    var blueprintsRoot = [packageRoot, subpath, server.name, version]
        .join(Platform.pathSeparator);
    new Directory(blueprintsRoot).createSync(recursive: true);
    var group = new _ApiGroupBlock.build(type);
    group.writeFile(blueprintsRoot);

    var route = _ApiRouteBlock.build(packageRoot, type, group, context);
    route.writeFile(blueprintsRoot);
    var action = _ApiActionBlock.build(packageRoot, route, context, request);
    action.writeFile(blueprintsRoot);
    var requestBlock = new _ApiRequestBlock.build(request, action);
    requestBlock.writeFile(blueprintsRoot);
    return new Future.value();
  }

  void checkPubspecExists(String rootPath) {
    var file =
        new File([rootPath, 'pubspec.yaml'].join(Platform.pathSeparator));
    if (!file.existsSync())
      throw new StateError(
          'Could not locate project root. pubspec.yaml not found in $rootPath');
  }
}
