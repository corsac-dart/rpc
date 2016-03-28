#!/bin/env dart
import 'dart:io';

void main(List<String> args) {
  var res = Process.runSync('pub', ['run', 'test'],
      environment: {'CORSAC_RPC_API_BLUEPRINT_PATH': 'doc/blueprint'});
  print(res.stdout);
}
