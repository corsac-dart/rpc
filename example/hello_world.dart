library hello_world;

import 'dart:io';

import 'package:corsac_rpc/corsac_rpc.dart';
import 'package:corsac_kernel/corsac_kernel.dart';
import 'package:logging/logging.dart';

class MyApplication extends ApiServer {
  @override final String prefix = '';
  @override final InternetAddress address;
  @override final int port;
  @override final Kernel kernel;

  MyApplication(this.address, this.port, this.kernel);

  @override
  List<Type> get apiResources => [HelloWorldResource];
}

@ApiResource(path: '/hello-world/{name}')
class HelloWorldResource {
  @ApiAction(method: 'GET', versions: const ['2', '3'])
  getHelloWorld(String name) {
    return new ApiResponse.json({'myNameIs': name});
  }
}

main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((r) {
    print(r);
  });
  final kernel = await Kernel.build('local', {}, []);
  final app = new MyApplication(InternetAddress.LOOPBACK_IP_V4, 8181, kernel);
  app.run();

  // for (var i = 0; i < Platform.numberOfProcessors; i++) {
  //   var response = new ReceivePort();
  //   Future<Isolate> remote = Isolate.spawn(startServer, response.sendPort);
  //   remote.then((isolate) {
  //     Logger.root.info('Started isolate ${i}');
  //   });
  // }
}

// startServer(SendPort initialReplyTo) async {
//   Logger.root.level = Level.ALL;
//   Logger.root.onRecord.listen((r) {
//     print(r);
//   });
//   final kernel = await Kernel.build('local', {}, []);
//   final app = new MyApplication(InternetAddress.LOOPBACK_IP_V4, 8181, kernel);
//   app.run(shared: true);
// }
