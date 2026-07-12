import 'package:flutter/cupertino.dart';
import 'package:cupertino_widgets/cupertino_widgets.dart';

import '../widgets/settings_ui.dart';
import 'alert_demo_page.dart';
import 'app_bar_demo_page.dart';
import 'button_demo_page.dart';
import 'date_picker_demo_page.dart';
import 'liquid_glass_demo_page.dart';
import 'menu_demo_page.dart';
import 'native_list_form_demo_page.dart';
import 'native_scaffold_demo_page.dart';
import 'native_searchable_demo_page.dart';
import 'progress_demo_page.dart';
import 'segmented_control_demo_page.dart';
import 'sheet_demo_page.dart';
import 'slider_demo_page.dart';
import 'standalone_tab_bar_demo_page.dart';
import 'text_field_demo_page.dart';
import 'toggle_demo_page.dart';

/// The demo catalog. The catalog itself is a [CupertinoNativeList] — a real
/// SwiftUI inset-grouped list — so the very first screen already shows native
/// rows, SF Symbol icons and iOS-correct section corners.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static final Map<String, WidgetBuilder> _routes = {
    'slider': (_) => const SliderDemoPage(),
    'toggle': (_) => const ToggleDemoPage(),
    'segmented': (_) => const SegmentedControlDemoPage(),
    'button': (_) => const ButtonDemoPage(),
    'menu': (_) => const MenuDemoPage(),
    'textfield': (_) => const TextFieldDemoPage(),
    'tabbar': (_) => const StandaloneTabBarDemoPage(),
    'scaffold': (_) => const NativeScaffoldDemoPage(),
    'searchable': (_) => const NativeSearchableDemoPage(),
    'listform': (_) => const NativeListFormDemoPage(),
    'liquidglass': (_) => const LiquidGlassDemoPage(),
    'sheet': (_) => const SheetDemoPage(),
    'datepicker': (_) => const DatePickerDemoPage(),
    'appbar': (_) => const AppBarDemoPage(),
    'alert': (_) => const AlertDemoPage(),
    'progress': (_) => const ProgressDemoPage(),
  };

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Cupertino Widgets',
      largeTitle: true,
      children: [
        const SizedBox(height: 8),
        CupertinoNativeList(
          style: CupertinoNativeListStyle.insetGrouped,
          onRowTap: (id) {
            final builder = _routes[id];
            if (builder != null) {
              Navigator.of(context).push(
                CupertinoPageRoute(builder: builder, title: 'Back'),
              );
            }
          },
          sections: [
            CupertinoNativeListSection(
              header: 'Controls',
              rows: [
                _row('slider', 'Slider',
                    CupertinoSymbols.slider, CupertinoColors.systemBlue),
                _row('toggle', 'Toggle', null, CupertinoColors.systemGreen,
                    rawSymbol: 'switch.2'),
                _row('segmented', 'Segmented Control', null,
                    CupertinoColors.systemOrange,
                    rawSymbol: 'rectangle.split.3x1'),
                _row('button', 'Button', null, CupertinoColors.systemPurple,
                    rawSymbol: 'hand.tap'),
                _row('menu', 'Popup Menu', CupertinoSymbols.ellipsisCircle,
                    CupertinoColors.systemIndigo),
                _row('textfield', 'Text Field', null,
                    CupertinoColors.systemTeal,
                    rawSymbol: 'character.cursor.ibeam'),
                _row('datepicker', 'Date Picker', CupertinoSymbols.calendar,
                    CupertinoColors.systemRed),
              ],
            ),
            CupertinoNativeListSection(
              header: 'Navigation',
              rows: [
                _row('tabbar', 'Tab Bar', CupertinoSymbols.squareGrid2x2,
                    CupertinoColors.systemPink),
                _row('scaffold', 'Native Scaffold', null,
                    CupertinoColors.systemBlue,
                    rawSymbol: 'iphone'),
                _row('searchable', 'Searchable',
                    CupertinoSymbols.magnifyingglass,
                    CupertinoColors.systemGrey),
                _row('sheet', 'Sheet', null, CupertinoColors.systemGreen,
                    rawSymbol: 'rectangle.portrait.bottomhalf.inset.filled'),
                _row('appbar', 'App Bar & Edge Effect', null,
                    CupertinoColors.systemIndigo,
                    rawSymbol: 'rectangle.topthird.inset.filled'),
              ],
            ),
            CupertinoNativeListSection(
              header: 'Views',
              rows: [
                _row('listform', 'List & Form', CupertinoSymbols.listBullet,
                    CupertinoColors.systemYellow),
                _row('liquidglass', 'Liquid Glass', null,
                    CupertinoColors.systemCyan,
                    rawSymbol: 'sparkles'),
              ],
            ),
            CupertinoNativeListSection(
              header: 'Feedback',
              footer: 'Every control on these pages is a real UIKit/SwiftUI '
                  'view rendered inside Flutter.',
              rows: [
                _row('alert', 'Alert', CupertinoSymbols.exclamationmarkTriangle,
                    CupertinoColors.systemRed),
                _row('progress', 'Progress', null, CupertinoColors.systemCyan,
                    rawSymbol: 'chart.bar.xaxis'),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static CupertinoNativeListRow _row(
    String id,
    String title,
    CupertinoSymbols? symbol,
    Color color, {
    String? rawSymbol,
  }) {
    return CupertinoNativeListRow(
      id: id,
      title: title,
      icon: symbol != null
          ? CupertinoNativeIcon.symbol(symbol, color: color)
          : CupertinoNativeIcon.named(rawSymbol!, color: color),
      showChevron: true,
    );
  }
}
