import 'package:flutter/foundation.dart';

/// The ready-made categories. Their names are translated at the UI edge.
enum PresetCategory {
  famousPeople,
  actors,
  singers,
  footballers,
  movies,
  series,
  cartoons,
  animals,
  countries,
  cities,
  food,
  brands,
  peopleWeKnow,
  anything,
}

/// What everyone writes names from: a preset, or one the host typed.
@immutable
final class GameCategory {
  const GameCategory.preset(PresetCategory this.preset) : custom = null;

  const GameCategory.custom(String this.custom) : preset = null;

  static const maxCustomLength = 40;

  final PresetCategory? preset;

  /// The host's own wording, shown as typed.
  final String? custom;

  @override
  bool operator ==(Object other) => other is GameCategory && other.preset == preset && other.custom == custom;

  @override
  int get hashCode => Object.hash(preset, custom);
}
