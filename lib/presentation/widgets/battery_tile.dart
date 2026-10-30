import 'package:flutter/widgets.dart';

class BatteryTile extends StatelessWidget {
  const BatteryTile({required this.label, required this.level, super.key});

  final String label;
  final int level;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [Text(label), Text('$level%')],
      ),
    );
  }
}
