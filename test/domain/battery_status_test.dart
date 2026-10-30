import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/domain/entities/battery_status.dart';

void main() {
  test('levels are null unless reported', () {
    const status = BatteryStatus(left: 50);
    expect(status.left, 50);
    expect(status.right, isNull);
    expect(status.caseLevel, isNull);
  });

  test('has value equality', () {
    expect(
      const BatteryStatus(left: 1, right: 2, caseLevel: 3),
      const BatteryStatus(left: 1, right: 2, caseLevel: 3),
    );
    expect(const BatteryStatus(left: 1), isNot(const BatteryStatus(left: 2)));
  });
}
