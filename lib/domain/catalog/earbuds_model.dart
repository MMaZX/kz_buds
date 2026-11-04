/// A known earbuds model. Used for appearance only (name, artwork, labels);
/// features always come from what the device reports.
class EarbudsModel {
  const EarbudsModel({
    required this.id,
    required this.displayName,
    this.eqPresetNames = const {},
  });

  final String id;
  final String displayName;

  /// EQ preset names by device mode, as the vendor app shows them; the
  /// firmware reports none.
  final Map<int, String> eqPresetNames;

  @override
  bool operator ==(Object other) => other is EarbudsModel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'EarbudsModel($id)';
}
