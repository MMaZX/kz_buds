import 'package:flutter/widgets.dart';
import 'package:hugeicons/hugeicons.dart';

import 'kz_metrics.dart';

typedef KzIconData = List<List<dynamic>>;

/// The only file that names icons from the icon package. Widgets use these
/// semantic names, so swapping libraries touches this file alone.
abstract final class KzIcons {
  static const KzIconData ear = HugeIcons.strokeRoundedEar;
  static const KzIconData earRings = HugeIcons.strokeRoundedEarRings01;
  static const KzIconData earbuds = HugeIcons.strokeRoundedAirpod01;
  static const KzIconData tap = HugeIcons.strokeRoundedTap01;
  static const KzIconData gameMode = HugeIcons.strokeRoundedGameController03;
  static const KzIconData eq = HugeIcons.strokeRoundedAudioWave01;
  static const KzIconData undo = HugeIcons.strokeRoundedUndo;
  static const KzIconData redo = HugeIcons.strokeRoundedRedo;
  static const KzIconData batteryEmpty = HugeIcons.strokeRoundedBatteryEmpty;
  static const KzIconData batteryLow = HugeIcons.strokeRoundedBatteryLow;
  static const KzIconData batteryMedium =
      HugeIcons.strokeRoundedBatteryMedium01;
  static const KzIconData batteryFull = HugeIcons.strokeRoundedBatteryFull;
  static const KzIconData batteryCharging =
      HugeIcons.strokeRoundedBatteryCharging01;
  static const KzIconData trash = HugeIcons.strokeRoundedDelete02;
  static const KzIconData edit = HugeIcons.strokeRoundedEdit02;
  static const KzIconData help = HugeIcons.strokeRoundedHelpSquare;
  static const KzIconData update = HugeIcons.strokeRoundedCircleArrowUp01;
  static const KzIconData menu = HugeIcons.strokeRoundedMenu01;
  static const KzIconData more = HugeIcons.strokeRoundedMoreVertical;
  static const KzIconData back = HugeIcons.strokeRoundedArrowLeft02;
  static const KzIconData close = HugeIcons.strokeRoundedCancel01;
  static const KzIconData bluetooth = HugeIcons.strokeRoundedBluetooth;
  static const KzIconData settings = HugeIcons.strokeRoundedSettings02;
  static const KzIconData home = HugeIcons.strokeRoundedHome01;
  static const KzIconData power = HugeIcons.strokeRoundedPower;
  static const KzIconData find = HugeIcons.strokeRoundedSearch01;
  static const KzIconData warning = HugeIcons.strokeRoundedAlert02;
  static const KzIconData check = HugeIcons.strokeRoundedTick02;
  static const KzIconData forward = HugeIcons.strokeRoundedArrowRight01;
}

class KzIcon extends StatelessWidget {
  const KzIcon(
    this.icon, {
    this.size,
    this.color,
    this.emphasized = false,
    super.key,
  });

  final KzIconData icon;
  final double? size;
  final Color? color;

  /// Selected or emphasized state: a heavier stroke.
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    return HugeIcon(
      icon: icon,
      color: color ?? theme.color,
      size: size ?? theme.size ?? 20,
      strokeWidth: emphasized ? KzStroke.iconEmphasis : KzStroke.icon,
    );
  }
}
