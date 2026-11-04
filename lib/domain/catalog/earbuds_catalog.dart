import '../entities/earbuds_identity.dart';
import 'earbuds_model.dart';

/// Known models, recognised from the device's own identity.
///
/// KZ earbuds report generic JieLi ids (vid 0x05D6, pid 0, uid 0), so the
/// name is the key for now; entries can add ids when a model has its own.
abstract final class EarbudsCatalog {
  static const kzCarolPro = EarbudsModel(
    id: 'kz-carol-pro',
    displayName: 'KZ Carol Pro',
    // As the KZ app lists them (user, 2026-11-04); modes 4 and 5 are its
    // two custom slots.
    eqPresetNames: {
      0: 'Standard',
      1: 'Bass Enhancement',
      2: 'Vocal Enhancement',
      3: 'High Resolution',
      4: 'Custom 1',
      5: 'Custom 2',
    },
  );

  static final _byName = <RegExp, EarbudsModel>{
    RegExp(r'\bcarol\s*pro\b', caseSensitive: false): kzCarolPro,
  };

  static EarbudsModel? match(EarbudsIdentity identity) {
    final name = identity.name;
    if (name == null) return null;
    for (final MapEntry(key: pattern, value: model) in _byName.entries) {
      if (pattern.hasMatch(name)) return model;
    }
    return null;
  }
}
