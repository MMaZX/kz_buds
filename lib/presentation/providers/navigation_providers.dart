import 'package:flutter_riverpod/flutter_riverpod.dart';

enum KzTab { home, eq, touch, settings }

class SelectedTabNotifier extends Notifier<KzTab> {
  @override
  KzTab build() => KzTab.home;

  void select(KzTab tab) => state = tab;
}

final selectedTabProvider = NotifierProvider<SelectedTabNotifier, KzTab>(
  SelectedTabNotifier.new,
);
