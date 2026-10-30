import 'package:flutter/material.dart';

class BatteryTile extends StatelessWidget {
  const BatteryTile({required this.label, required this.level, super.key});

  final String label;
  final int level;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text('$level%', style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }
}
