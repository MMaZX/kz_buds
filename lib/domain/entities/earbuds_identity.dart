/// What the connected earbuds say about themselves. Any field may be
/// unknown.
class EarbudsIdentity {
  const EarbudsIdentity({this.name, this.vendorId, this.productId});

  final String? name;
  final int? vendorId;
  final int? productId;

  @override
  bool operator ==(Object other) =>
      other is EarbudsIdentity &&
      other.name == name &&
      other.vendorId == vendorId &&
      other.productId == productId;

  @override
  int get hashCode => Object.hash(name, vendorId, productId);

  @override
  String toString() => 'EarbudsIdentity($name)';
}
