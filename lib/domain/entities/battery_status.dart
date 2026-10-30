/// Battery levels in percent (0-100). A `null` level means the device does not
/// report it; it must never be defaulted or invented.
class BatteryStatus {
  const BatteryStatus({this.left, this.right, this.caseLevel});

  final int? left;
  final int? right;
  final int? caseLevel;

  @override
  bool operator ==(Object other) =>
      other is BatteryStatus &&
      other.left == left &&
      other.right == right &&
      other.caseLevel == caseLevel;

  @override
  int get hashCode => Object.hash(left, right, caseLevel);

  @override
  String toString() =>
      'BatteryStatus(left: $left, right: $right, caseLevel: $caseLevel)';
}
