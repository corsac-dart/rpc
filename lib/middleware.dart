/// Additional middlewares for [ApiServer].
///
///  This library provides following middlewares:
///
///  * [PrefixMiddleware] if API resources are prefixed, e.g. `/api/users`
///  * [VersionMiddleware] if API is versioned. There are two strategies
///    available: version as URL-prefix (`/v1/users`) or in the `Accept` header.
library corsac_rpc.middleware;

import 'dart:async';
import 'dart:io';

import 'package:corsac_middleware/corsac_middleware.dart';
import 'package:corsac_rpc/corsac_rpc.dart';

part 'src/middleware/prefix.dart';
part 'src/middleware/version.dart';
