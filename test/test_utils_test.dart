library corsac_rpc.test.test_utils;

import 'package:corsac_kernel/corsac_kernel.dart';
import 'package:corsac_rpc/corsac_rpc.dart';
import 'package:corsac_rpc/test.dart';

@ApiResource(path: '/users/{id}')
class UserResource {
  @ApiMethod.GET
  getUser(int id) {
    return new HttpApiResponse.json({"id": id, "name": "Burt Macklin"});
  }
}

main() {
  setUpApiServer(() async {
    final kernel = await Kernel.build('test', {}, []);
    return new ApiServer(kernel, [UserResource]);
  });

  group('apiTest:', () {
    apiTest('it works', (ApiClient client) async {
      var request = await client.get('/users/4');
      expect(request, responseStatus(HttpStatus.OK));
      expect(request, responseBody(contains('Burt Macklin')));
    });
  });
}
