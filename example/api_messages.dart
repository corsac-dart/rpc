library hello_world;

import 'package:corsac_rpc/corsac_rpc.dart';
import 'package:corsac_kernel/corsac_kernel.dart';
import 'package:logging/logging.dart';

/// Users collection
@ApiResource(path: '/users')
class HelloWorldResource {
  /// Create new user
  @ApiMethod.POST
  postUser(UserApiMessage message) {
    return new HttpApiResponse.json({
      'myNameIs': message.name,
      'birthDate': message.birthDate.toString(),
      'isSubscribed': message.isSubscribed
    });
  }
}

@ApiMessage()
class UserApiMessage {
  @ApiField(required: true, example: 'John Doe')
  String name;
  @ApiField(required: true, example: '2015-01-03T23:03:24Z')
  DateTime birthDate;
  @ApiField(example: 'true')
  bool isSubscribed;
}

main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((r) {
    print(r);
    if (r.error != null) {
      print(r.error);
      print(r.stackTrace);
    }
  });

  final kernel = await Kernel.build('local', {}, []);
  final app = new ApiServer(kernel, [HelloWorldResource]);
  app.start();
}
