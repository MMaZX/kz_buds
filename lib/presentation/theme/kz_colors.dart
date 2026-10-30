import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'kz_color_scheme.dart';

/// Typed access to the semantic colors carried in `ShadColorScheme.custom`.
class KzColors {
  const KzColors(this.scheme);

  /// Highest level still shown as critical.
  static const criticalMaxLevel = 20;

  final ShadColorScheme scheme;

  Color _of(String key) => scheme.custom[key]!;

  Color get brand => _of(KzColorKeys.brand);
  Color get brandForeground => _of(KzColorKeys.brandForeground);
  Color get success => _of(KzColorKeys.success);
  Color get warning => _of(KzColorKeys.warning);
  Color get batteryOk => _of(KzColorKeys.batteryOk);
  Color get batteryCritical => _of(KzColorKeys.batteryCritical);
  Color get batteryTrack => _of(KzColorKeys.batteryTrack);

  Color battery(int level) =>
      level <= criticalMaxLevel ? batteryCritical : batteryOk;
}
