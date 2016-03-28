library corsac_rpc.test.test_utils;

import 'package:corsac_kernel/corsac_kernel.dart';
import 'package:corsac_rpc/corsac_rpc.dart';
import 'package:corsac_rpc/test.dart';

/// User resource
///
/// Exposes endpoints to manipulate individual user.
@ApiResource(path: '/users/{id}', group: 'Users')
class UserResource {
  /// Get user
  ///
  /// Returns individual user specified by `id`.
  @ApiMethod.GET
  getUser(int id) {
    return new HttpApiResponse.json({'id': id, 'name': 'Burt Macklin'});
  }
}

main() {
  setUpApiServer(() async {
    final module = new ApiServerKernelModule();
    module.apiResources = [UserResource];
    final kernel = await Kernel.build('test', {}, [module]);
    return new ApiServer(kernel);
  });

  group('apiTest:', () {
    apiTest('it works', (ApiClient client) async {
      var request = await client.get('/users/4');
      expect(request, responseStatus(HttpStatus.OK));
      expect(request, responseBody(contains('Burt Macklin')));
    });
  });
}
