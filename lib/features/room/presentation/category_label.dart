import '../../../core/l10n/l10n.dart';
import '../domain/category.dart';

/// The category as the host reads it, in the app's language.
String categoryLabel(AppLocalizations l10n, GameCategory category) => switch (category.preset) {
  null => category.custom ?? '',
  PresetCategory.famousPeople => l10n.categoryFamousPeople,
  PresetCategory.actors => l10n.categoryActors,
  PresetCategory.singers => l10n.categorySingers,
  PresetCategory.footballers => l10n.categoryFootballers,
  PresetCategory.movies => l10n.categoryMovies,
  PresetCategory.series => l10n.categorySeries,
  PresetCategory.cartoons => l10n.categoryCartoons,
  PresetCategory.animals => l10n.categoryAnimals,
  PresetCategory.countries => l10n.categoryCountries,
  PresetCategory.cities => l10n.categoryCities,
  PresetCategory.food => l10n.categoryFood,
  PresetCategory.brands => l10n.categoryBrands,
  PresetCategory.peopleWeKnow => l10n.categoryPeopleWeKnow,
  PresetCategory.anything => l10n.categoryAnything,
};
