import 'package:flutter/material.dart';
import 'package:flutter_cupertino/flutter_cupertino.dart';

import 'app.dart';
import 'entrypoints.dart';

void main() {
  // Scaffold body engines re-enter main() with a special route; this runs
  // the matching body widget and skips the regular app.
  if (CupertinoNativeScaffold.maybeRun(scaffoldRoutes())) return;

  runApp(const MyApp());
}
