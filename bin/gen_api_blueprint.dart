#!/bin/env dart
import 'dart:io';

void main(List<String> args) {
  Process.start('pub', [
    'run',
    'test'
  ], environment: {
    'CORSAC_RPC_API_BLUEPRINT_PATH': 'doc/blueprint'
  }).then((p) {
    p.stdout.pipe(stdout);
  });
}
