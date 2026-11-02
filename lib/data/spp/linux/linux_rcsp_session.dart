import '../../../domain/entities/detected_earbuds.dart';
import '../rcsp_spp_session.dart';

/// Opens an RCSP session to the first detected earbuds on Linux.
///
/// [connectOs] runs first so the earbuds come up as the OS connects them,
/// audio profiles included. An RFCOMM socket alone brings up only the
/// baseband link, which leaves the earbuds "connected" with no audio device
/// (odd/tasks/carol-pro-bluetooth.md L22).
Future<RcspSppSession> openLinuxRcspSession({
  required Future<List<DetectedEarbuds>> Function() discover,
  required Future<void> Function(String id) connectOs,
  required Future<SppLink> Function(String id) openLink,
  void Function(String message)? log,
}) async {
  final found = await discover();
  if (found.isEmpty) throw StateError('No paired JieLi earbuds found');
  final earbuds = found.first;
  final id = earbuds.id;
  log?.call('BlueZ connect (audio profiles)');
  await connectOs(id);
  log?.call('RFCOMM connect and RCSP auth');
  return RcspSppSession.open(() => openLink(id), osName: earbuds.name);
}
