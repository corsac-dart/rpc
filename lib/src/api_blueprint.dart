part of corsac_rpc.test;

List readDocComment(SourceLocation location) {
  var file = new File.fromUri(location.sourceUri);
  var lines = file.readAsLinesSync().take(location.line).toList();
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

class ApiGroupBlock {
  final String name;
  final String body;

  String get sanitizedName => name.replaceAll(' ', '-').toLowerCase();

  ApiGroupBlock(this.name, {this.body: ''});

  factory ApiGroupBlock.build(Type resource) {
    ApiResource res = reflectType(resource)
        .metadata
        .firstWhere((_) => _.reflectee is ApiResource)
        .reflectee;
    return new ApiGroupBlock(res.group);
  }

  @override
  String toString() => '# Group ${name}\n\n${body}\n\n';

  void writeFile(String path) {
    var filename =
        [path, "05_${sanitizedName}_01.apib"].join(Platform.pathSeparator);
    new File(filename).writeAsStringSync(this.toString());
  }
}

class ApiRouteBlock {
  final ApiGroupBlock group;
  final String name;
  final String route;
  final String description;
  final List<ApiParam> parameters;

  String get sanitizedRoute => route
      .replaceFirst('/', '')
      .replaceAll('/', '-')
      .replaceAll('{', '')
      .replaceAll('}', '');

  ApiRouteBlock(
      this.group, this.name, this.route, this.description, this.parameters);

  factory ApiRouteBlock.build(
      Type resource, ApiGroupBlock group, MiddlewareContext context) {
    ApiResource res = reflectType(resource)
        .metadata
        .firstWhere((_) => _.reflectee is ApiResource)
        .reflectee;
    var doc = readDocComment(reflectType(resource).location);
    var paramNames = context.matchResult.parameters.keys;
    List<ApiParam> apiParams = [];
    for (var methodParam in context.apiAction.parameters) {
      var name = MirrorSystem.getName(methodParam.simpleName);
      if (!paramNames.contains(name)) continue;

      var type = methodParam.type.reflectedType.toString();
      apiParams.add(new ApiParam(name, type, true, null, null));
    }
    return new ApiRouteBlock(group, doc.first, res.path, doc.last, apiParams);
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

class ApiParam {
  final String name;
  final String type;
  final bool required;
  final String description;
  final String example;

  ApiParam(this.name, this.type, this.required, this.description, this.example);

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

class ApiActionBlock {
  final String name;
  final String method;
  final String description;
  final ApiRouteBlock route;

  ApiActionBlock(this.name, this.method, this.description, this.route);

  factory ApiActionBlock.build(
      ApiRouteBlock route, MiddlewareContext context, HttpRequestMock request) {
    var doc = readDocComment(context.apiAction.location);
    return new ApiActionBlock(doc.first, request.method, doc.last, route);
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

class ApiRequestBlock {
  final HttpRequestMock request;
  final ApiActionBlock action;

  ApiRequestBlock(this.request, this.action);

  factory ApiRequestBlock.build(
      HttpRequestMock request, ApiActionBlock action) {
    return new ApiRequestBlock(request, action);
  }

  @override
  toString() {
    var buf = new StringBuffer();
    if (request.body is String && request.body.isNotEmpty) {
      var contentType = request.headers.contentType.mimeType;
      buf..writeln('+ Request (${contentType})')..writeln();
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
  void generate(
      MiddlewareContext context, HttpRequestMock request, ApiServer server) {
    if (!context.matchResult.hasMatch) return;
    var subpath = Platform.environment['CORSAC_RPC_API_BLUEPRINT_PATH'];
    if (subpath == null) return;

    Type type = context.matchResult.data;
    var m = reflectType(type);
    var sourcePath =
        m.location.sourceUri.toFilePath(windows: Platform.isWindows);
    if (sourcePath.contains('.pub-cache')) {
      throw new StateError('Can not generate API blueprints for API'
          ' resource from dependency package.');
    }
    var uri = new Uri.file(sourcePath, windows: Platform.isWindows);
    var s = uri.pathSegments.takeWhile((_) => _ != 'lib' && _ != 'test');
    var rootPath =
        uri.replace(pathSegments: s).toFilePath(windows: Platform.isWindows);
    checkPubspecExists(rootPath);

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
    var blueprintsRoot =
        [rootPath, subpath, server.name, version].join(Platform.pathSeparator);
    new Directory(blueprintsRoot).createSync(recursive: true);
    var group = new ApiGroupBlock.build(type);
    group.writeFile(blueprintsRoot);
    var route = new ApiRouteBlock.build(type, group, context);
    route.writeFile(blueprintsRoot);
    var action = new ApiActionBlock.build(route, context, request);
    action.writeFile(blueprintsRoot);
    var requestBlock = new ApiRequestBlock.build(request, action);
    requestBlock.writeFile(blueprintsRoot);
  }

  void checkPubspecExists(String rootPath) {
    var file =
        new File([rootPath, 'pubspec.yaml'].join(Platform.pathSeparator));
    if (!file.existsSync())
      throw new StateError(
          'Could not locate project root. pubspec.yaml not found in $rootPath');
  }
}
