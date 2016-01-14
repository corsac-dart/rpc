library corsac_rpc.tests.api_fields;

import 'dart:mirrors';
import 'package:test/test.dart';
import 'package:corsac_router/corsac_router.dart';
import 'package:corsac_rpc/corsac_rpc.dart';

void main() {
  group('ApiFields:', () {
    MethodMirror method;

    setUp(() {
      var mirror = reflectClass(TestResource);
      method = mirror.declarations[#getTest];
    });

    test('it parses supported type values', () {
      var result1 = ApiFieldResolver.parse('2015-01-01', reflectType(DateTime));
      expect(result1, new isInstanceOf<DateTime>());
      expect(result1, equals(DateTime.parse('2015-01-01')));

      var result2 = ApiFieldResolver.parse('20', reflectType(int));
      expect(result2, equals(20));

      var result3 = ApiFieldResolver.parse('ping', reflectType(String));
      expect(result3, equals('ping'));
    });

    test('it resolves query parameter fields', () {
      var resolver = const QueryApiFieldResolver();
      var field1 = method.parameters.firstWhere((_) => _.simpleName == #from);
      var field2 = method.parameters.firstWhere((_) => _.simpleName == #limit);
      var field3 = method.parameters.firstWhere((_) => _.simpleName == #q);

      var request = new HttpApiRequest(
          'GET', Uri.parse('/test?from=2015-01-01&limit=20&q=ping'), {}, null);
      var result1 = resolver.resolve(field1, request, null);
      expect(result1, new isInstanceOf<DateTime>());
      expect(result1, equals(DateTime.parse('2015-01-01')));

      var result2 = resolver.resolve(field2, request, null);
      expect(result2, equals(20));

      var result3 = resolver.resolve(field3, request, null);
      expect(result3, equals('ping'));
    });

    test('it resolves resource path parameter fields', () {
      var resolver = const ResourceParameterApiFieldResolver();
      var field1 = method.parameters.firstWhere((_) => _.simpleName == #name);

      var request = new HttpApiRequest('GET',
          Uri.parse('/test/{name}?from=2015-01-01&limit=20&q=ping'), {}, null);
      var match = new MatchResult(
          new HttpResource('/test/{name}', ['GET']), null, {'name': 'joe'}, {});
      var result1 = resolver.resolve(field1, request, match);
      expect(result1, equals('joe'));
    });
  });
}

class TestResource {
  getTest(String name, {DateTime from, int limit, String q}) {}
}
