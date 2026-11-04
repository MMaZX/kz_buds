import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/domain/catalog/earbuds_catalog.dart';
import 'package:kz_buds/domain/entities/earbuds_identity.dart';

void main() {
  test('recognises the Carol Pro by name in any case or prefix', () {
    for (final name in ['Carol Pro', 'CAROL PRO', 'KZ Carol Pro', 'carolpro']) {
      expect(
        EarbudsCatalog.match(EarbudsIdentity(name: name)),
        EarbudsCatalog.kzCarolPro,
        reason: name,
      );
    }
  });

  test('does not match other names', () {
    for (final name in ['Carol', 'Castor Pro', 'Pro Carol', '']) {
      expect(
        EarbudsCatalog.match(EarbudsIdentity(name: name)),
        isNull,
        reason: name,
      );
    }
  });

  test('an unknown identity has no model', () {
    expect(EarbudsCatalog.match(const EarbudsIdentity()), isNull);
  });

  test('the Carol Pro names its EQ presets as the KZ app shows them', () {
    expect(EarbudsCatalog.kzCarolPro.eqPresetNames, {
      0: 'Standard',
      1: 'Bass Enhancement',
      2: 'Vocal Enhancement',
      3: 'High Resolution',
      4: 'Custom 1',
      5: 'Custom 2',
    });
  });
}
