/// Corsac RPC library inspired by Dart's `rpc` package.
///
/// Provides "officially" (Corsac-style) flavored abstraction for implementing
/// HTTP server applications.
library corsac_rpc;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:mirrors';

import 'package:corsac_di/corsac_di.dart';
import 'package:corsac_kernel/corsac_kernel.dart';
import 'package:corsac_middleware/corsac_middleware.dart';
import 'package:corsac_router/corsac_router.dart';
import 'package:logging/logging.dart';
import 'package:rpc/rpc.dart'
    show HttpApiRequest, HttpApiResponse, MediaMessage;

export 'package:rpc/rpc.dart'
    show HttpApiRequest, HttpApiResponse, MediaMessage;

part 'src/annotations.dart';
part 'src/api_fields.dart';
part 'src/api_responses.dart';
part 'src/errors.dart';
part 'src/middleware/context.dart';
part 'src/middleware/error.dart';
part 'src/middleware/prefix.dart';
part 'src/middleware/router.dart';
part 'src/middleware/version.dart';
part 'src/resources.dart';
part 'src/server.dart';

Logger _logger = new Logger('HttpApplication');
