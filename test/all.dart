library corsac_rpc.tests.all;

import 'api_fields_test.dart' as api_fields;
import 'api_responses_test.dart' as api_responses;
import 'middleware/prefix_test.dart' as prefix;
import 'middleware/router_test.dart' as router;
import 'middleware/version_test.dart' as version;

void main() {
  api_fields.main();
  api_responses.main();
  prefix.main();
  router.main();
  version.main();
}
