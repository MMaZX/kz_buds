import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/fake/fake_earbuds_adapter.dart';
import 'presentation/pages/device_home_page.dart';
import 'presentation/providers/earbuds_providers.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [earbudsPortProvider.overrideWithValue(FakeEarbudsAdapter())],
      child: const KzBudsApp(),
    ),
  );
}

class KzBudsApp extends StatelessWidget {
  const KzBudsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KZ Buds',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const DeviceHomePage(),
    );
  }
}
