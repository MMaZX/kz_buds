/// A known earbuds model. Used for appearance only (name, artwork);
/// features always come from what the device reports.
class EarbudsModel {
  const EarbudsModel({required this.id, required this.displayName});

  final String id;
  final String displayName;

  @override
  bool operator ==(Object other) => other is EarbudsModel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'EarbudsModel($id)';
}
