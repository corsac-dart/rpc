/// Corsac RPC library inspired by Dart's `rpc` package.
///
/// Provides abstraction for implementing extensible HTTP API applications.
library corsac_rpc;

import 'dart:async';
import 'dart:io';
import 'dart:mirrors';

import 'package:collection/collection.dart';
import 'package:corsac_kernel/corsac_kernel.dart';
import 'package:corsac_router/corsac_router.dart';
import 'package:logging/logging.dart';

import 'http.dart';
import 'pipeline.dart';

export 'http.dart';
export 'pipeline.dart';

part 'src/annotations.dart';
part 'src/api_fields.dart';
part 'src/errors.dart';
part 'src/middleware_context.dart';
part 'src/middlewares.dart';
part 'src/resources.dart';
part 'src/server.dart';

Logger _logger = new Logger('ApiServer');
