library hello_world;

import 'package:corsac_rpc/corsac_rpc.dart';
import 'package:logging/logging.dart';

@ApiResource(path: '/hello-world/{name}')
class HelloWorldResource {
  @ApiMethod.GET
  getHelloWorld(String name) {
    return new HttpApiResponse.json({'myNameIs': name});
  }
}

main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((r) => print(r));

  final kernel = await Kernel.build('local', {}, []);
  final app = new ApiServer(kernel, [HelloWorldResource]);
  app.start();
}

// for (var i = 0; i < Platform.numberOfProcessors; i++) {
//   var response = new ReceivePort();
//   Future<Isolate> remote = Isolate.spawn(startServer, response.sendPort);
//   remote.then((isolate) {
//     Logger.root.info('Started isolate ${i}');
//   });
// }

// startServer(SendPort initialReplyTo) async {
//   Logger.root.level = Level.ALL;
//   Logger.root.onRecord.listen((r) {
//     print(r);
//   });
//   final kernel = await Kernel.build('local', {}, []);
//   final app = new MyApplication(InternetAddress.LOOPBACK_IP_V4, 8181, kernel);
//   app.run(shared: true);
// }
