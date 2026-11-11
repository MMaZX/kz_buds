import 'package:bluetooth_rfcomm/bluetooth_rfcomm.dart';
import 'package:bluetooth_rfcomm/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/spp/android/rfcomm_earbuds_discovery.dart';
import 'package:kz_buds/domain/entities/detected_earbuds.dart';

void main() {
  // Class of Device values: major class in bits 8-12.
  const headset = 0x240404;
  const phone = 0x5a020c;

  BluetoothDevice device(String address, {String? name, int? cod}) =>
      BluetoothDevice(
        id: DeviceId.address(address),
        name: name,
        deviceClass: cod,
      );

  test('lists audio devices first, then those of unknown class', () {
    final candidates = rfcommEarbudsCandidates([
      device('00:00:00:00:00:01', name: 'Unknown'),
      device('00:00:00:00:00:02', name: 'Carol Pro', cod: headset),
    ]);

    expect(candidates, const [
      DetectedEarbuds(id: '00:00:00:00:00:02', name: 'Carol Pro'),
      DetectedEarbuds(id: '00:00:00:00:00:01', name: 'Unknown'),
    ]);
  });

  test('lists devices of another major class last instead of dropping', () {
    final candidates = rfcommEarbudsCandidates([
      device('00:00:00:00:00:03', name: 'Phone', cod: phone),
      device('00:00:00:00:00:01', name: 'Unknown'),
      device('00:00:00:00:00:02', name: 'Carol Pro', cod: headset),
    ]);

    expect(candidates.map((e) => e.name), ['Carol Pro', 'Unknown', 'Phone']);
  });

  test('drops devices without an address', () {
    final candidates = rfcommEarbudsCandidates([
      const BluetoothDevice(id: DeviceId.opaque('token'), deviceClass: headset),
    ]);

    expect(candidates, isEmpty);
  });

  test('keeps an unnamed device with an empty name', () {
    final candidates = rfcommEarbudsCandidates([
      device('00:00:00:00:00:04', cod: headset),
    ]);

    expect(candidates, const [
      DetectedEarbuds(id: '00:00:00:00:00:04', name: ''),
    ]);
  });

  test('keeps only the devices the OS has connected', () {
    final candidates = rfcommEarbudsCandidates(
      [
        device('00:00:00:00:00:01', name: 'Q37', cod: headset),
        device('00:00:00:00:00:0A', name: 'Carol Pro'),
        device('00:00:00:00:00:03', name: 'Speaker', cod: headset),
      ],
      connected: {'00:00:00:00:00:0a'},
    );

    expect(candidates, const [
      DetectedEarbuds(id: '00:00:00:00:00:0A', name: 'Carol Pro'),
    ]);
  });

  test('lists nothing when the OS has no device connected', () {
    final candidates = rfcommEarbudsCandidates([
      device('00:00:00:00:00:02', name: 'Carol Pro', cod: headset),
    ], connected: const {});

    expect(candidates, isEmpty);
  });

  group('RfcommEarbudsDiscovery', () {
    BluetoothRfcomm bluetoothWith(List<BluetoothDevice> bonded) =>
        BluetoothRfcomm(
          platform: FakeBluetoothRfcommPlatform()..bonded.addAll(bonded),
        );

    final bonded = [
      device('00:00:00:00:00:01', name: 'Q37', cod: headset),
      device('00:00:00:00:00:02', name: 'Carol Pro'),
    ];

    test('asks the OS which devices are connected', () async {
      final discovery = RfcommEarbudsDiscovery(
        bluetoothWith(bonded),
        connectedAddresses: () async => {'00:00:00:00:00:02'},
      );

      final found = await discovery.pairedEarbuds();

      expect(found.map((e) => e.name), ['Carol Pro']);
    });

    test('keeps every bonded device when the OS cannot tell', () async {
      final discovery = RfcommEarbudsDiscovery(
        bluetoothWith(bonded),
        connectedAddresses: () async => null,
      );

      final found = await discovery.pairedEarbuds();

      expect(found.map((e) => e.name), ['Q37', 'Carol Pro']);
    });
  });
}
