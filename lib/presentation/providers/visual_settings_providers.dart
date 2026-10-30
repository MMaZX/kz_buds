import 'package:flutter_riverpod/flutter_riverpod.dart';

class KzVisualSettings {
  const KzVisualSettings({this.reduceTransparency = false});

  final bool reduceTransparency;

  KzVisualSettings copyWith({bool? reduceTransparency}) => KzVisualSettings(
    reduceTransparency: reduceTransparency ?? this.reduceTransparency,
  );
}

class VisualSettingsNotifier extends Notifier<KzVisualSettings> {
  @override
  KzVisualSettings build() => const KzVisualSettings();

  void setReduceTransparency(bool value) =>
      state = state.copyWith(reduceTransparency: value);
}

/// In memory for now; persistence arrives later through a settings port.
final visualSettingsProvider =
    NotifierProvider<VisualSettingsNotifier, KzVisualSettings>(
      VisualSettingsNotifier.new,
    );
