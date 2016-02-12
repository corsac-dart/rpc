library corsac_rpc.tests.all;

import 'api_fields_test.dart' as api_fields;
import 'http_test.dart' as http;
import 'pipeline_test.dart' as pipeline;
import 'middleware/prefix_test.dart' as prefix;
import 'middleware/router_test.dart' as router;
import 'middleware/version_test.dart' as version;

void main() {
  api_fields.main();
  http.main();
  pipeline.main();
  prefix.main();
  router.main();
  version.main();
}
