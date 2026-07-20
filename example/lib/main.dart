import 'package:flutter/material.dart';
import 'package:cupertino_widgets/cupertino_widgets.dart';

import 'app.dart';
import 'scaffold_routes.dart';

void main() {
  if (CupertinoNativeScaffold.maybeRun(scaffoldRoutes())) return;
  runApp(const MyApp());
  // Warm the shared engine group in the background so the first body a
  // native scaffold boots is cheap. Bodies boot lazily on first visit, then
  // park & re-attach on later visits (no reload, Dart state kept). Pass
  // routes: ['home'] only to pre-boot a page shown immediately at launch.
  CupertinoNativeScaffold.prewarm();
}
