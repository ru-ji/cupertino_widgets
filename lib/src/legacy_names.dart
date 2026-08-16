/// Deprecated aliases kept so code written against the pre-0.1.0 names keeps
/// compiling. Each will be removed in 0.3.0.
///
/// Type aliases carry constructors, enum values and `values` through
/// transparently, so the only migration is a find-and-replace — except where
/// noted below, where the replacement type spells a value differently.
library;

import 'package:flutter/cupertino.dart' show OverlayVisibilityMode;
import 'package:flutter/widgets.dart' show TextAlignVertical;

import 'cupertino_native_glass_container.dart';
import 'cupertino_native_switch.dart';
import 'cupertino_native_tab_bar.dart';

/// Renamed to match Flutter's [CupertinoSwitch]. SwiftUI calls the control
/// `Toggle`; the Dart-facing name now follows Flutter instead.
@Deprecated(
  'Renamed to CupertinoNativeSwitch, matching Flutter\'s CupertinoSwitch. '
  'Will be removed in 0.3.0.',
)
typedef CupertinoNativeToggle = CupertinoNativeSwitch;

@Deprecated(
  'Renamed to CupertinoScrollEdgeEffectStyle, which no longer collides with '
  'the CupertinoScrollEdgeEffect widget. Will be removed in 0.3.0.',
)
typedef CupertinoNativeScrollEdgeEffect = CupertinoScrollEdgeEffectStyle;

@Deprecated(
  'Renamed to CupertinoGlassShape, to match CupertinoGlassVariant. '
  'Will be removed in 0.3.0.',
)
typedef CupertinoNativeGlassShape = CupertinoGlassShape;

/// Replaced by Flutter's own [TextAlignVertical] — the type
/// `TextField.textAlignVertical` takes. `top`, `center` and `bottom` all exist
/// on it, so this alias is a drop-in.
@Deprecated(
  'Use TextAlignVertical from package:flutter/widgets.dart. '
  'Will be removed in 0.3.0.',
)
typedef CupertinoNativeTextVerticalAlignment = TextAlignVertical;

/// Replaced by Flutter's own [OverlayVisibilityMode] — the type
/// `CupertinoTextField.clearButtonMode` takes.
///
/// `never` and `always` are unchanged, but two values are spelled differently
/// and this alias cannot bridge them:
///
/// - `whileEditing` → [OverlayVisibilityMode.editing]
/// - `unlessEditing` → [OverlayVisibilityMode.notEditing]
@Deprecated(
  'Use OverlayVisibilityMode from package:flutter/cupertino.dart, replacing '
  'whileEditing with editing and unlessEditing with notEditing. '
  'Will be removed in 0.3.0.',
)
typedef CupertinoNativeClearButtonMode = OverlayVisibilityMode;
