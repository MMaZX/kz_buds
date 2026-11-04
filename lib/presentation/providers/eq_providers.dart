import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/eq_settings.dart';
import 'earbuds_providers.dart';

/// Read again on every link change, like the capabilities.
final eqProfileProvider = FutureProvider<EqProfile?>((ref) {
  ref.watch(connectionProvider);
  return ref.watch(earbudsPortProvider).eqProfile();
});

final eqSettingsProvider = StreamProvider<EqSettings>(
  (ref) => ref.watch(earbudsPortProvider).watchEq(),
);

/// The preset's own name, else the model's name for that mode ([names],
/// from the catalog), else "Custom" for the editable slot, else its 1-based
/// number: the RCSP firmware names none of them.
String eqPresetLabel(
  EqProfile profile,
  EqPresetData preset, {
  Map<int, String> names = const {},
}) =>
    preset.name ??
    names[preset.mode] ??
    (preset.mode == profile.customMode
        ? 'Custom'
        : 'Preset ${preset.mode + 1}');
