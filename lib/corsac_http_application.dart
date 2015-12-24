/// Corsac HTTP application library.
///
/// Provides "officially" (Corsac-style) flavored abstraction for implementing
/// HTTP server applications.
library corsac_http_application;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:mirrors';

import 'package:corsac_kernel/corsac_kernel.dart';
import 'package:corsac_middleware/corsac_middleware.dart';
import 'package:corsac_router/corsac_router.dart';

part 'src/application.dart';
part 'src/controllers.dart';
part 'src/middleware/router.dart';
