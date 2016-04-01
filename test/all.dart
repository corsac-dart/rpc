library corsac_rpc.tests.all;

import 'api_fields_test.dart' as api_fields;
import 'content_test.dart' as content;
import 'errors_test.dart' as errors;
import 'http_test.dart' as http;
import 'pipeline_test.dart' as pipeline;
import 'test_utils_test.dart' as test_utils;
import 'middleware/action_invoker_test.dart' as action_invoker;
import 'middleware/action_resolver_test.dart' as action_resolver;
import 'middleware/prefix_test.dart' as prefix;
import 'middleware/router_test.dart' as router;
import 'middleware/version_test.dart' as version;

void main() {
  api_fields.main();
  content.main();
  errors.main();
  http.main();
  pipeline.main();
  test_utils.main();
  action_invoker.main();
  action_resolver.main();
  prefix.main();
  router.main();
  version.main();
}
