#!/usr/bin/env dart

import 'dart:io';
import '../lib/src/twirp_code_generator.dart';

void main() {
  TwirpCodeGenerator(stdin, stdout).generate();
}
