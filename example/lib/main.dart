import 'package:flutter/material.dart';
import 'package:cupertino_widgets/cupertino_widgets.dart';

import 'app.dart';
import 'entrypoints.dart';

void main() {
  if (CupertinoNativeScaffold.maybeRun(scaffoldRoutes())) return;
  runApp(const MyApp());
  // Fully boot the scaffold's initial tab body ('home') in the background so
  // the first native scaffold shows its Flutter content immediately, and keep
  // the shared engine group warm for every other route.
  CupertinoNativeScaffold.prewarm(routes: ['home']);
}
