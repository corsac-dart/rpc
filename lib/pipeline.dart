/// Middleware pipeline for Corsac RPC.
library corsac_rpc.pipeline;

import 'dart:async';
import 'dart:collection';
import 'package:corsac_rpc/http.dart';

class Pipeline {
  final Set<Middleware> beforeHandlers = new Set();
  final Set<Middleware> mainHandlers;

  /// Pipeline constructor.
  Pipeline(this.mainHandlers);

  /// Executes middleware pipeline.
  Future<HttpApiResponse> handle(HttpApiRequest request, Object context) {
    Queue queue = new Queue.from(beforeHandlers)..addAll(mainHandlers);
    Next next = new Next(queue);

    return next.handle(request, null, context);
  }
}

abstract class Middleware {
  /// Handles [request].
  Future<HttpApiResponse> handle(
      HttpApiRequest request, Object context, Next next);
}

class Next {
  Queue<Middleware> _handlers;
  Next(this._handlers);

  Future<HttpApiResponse> handle(
      HttpApiRequest request, HttpApiResponse response, Object context) {
    if (this._handlers.isEmpty) {
      return new Future.value(response);
    } else {
      Middleware handler = this._handlers.removeFirst();
      return handler.handle(request, context, this);
    }
  }
}
