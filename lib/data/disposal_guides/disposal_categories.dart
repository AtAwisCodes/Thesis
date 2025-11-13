/// Disposal Categories and Information System
/// Contains comprehensive guides for proper waste disposal

enum DisposalCategory {
  plasticBottles,
  cans,
  cartons,
  unusedClothes,
  glass,
}

extension DisposalCategoryExtension on DisposalCategory {
  String get name {
    switch (this) {
      case DisposalCategory.plasticBottles:
        return 'Plastic Bottles';
      case DisposalCategory.cans:
        return 'Cans';
      case DisposalCategory.cartons:
        return 'Cartons';
      case DisposalCategory.unusedClothes:
        return 'Unused Clothes';
      case DisposalCategory.glass:
        return 'Glass';
    }
  }

  String get icon {
    switch (this) {
      case DisposalCategory.plasticBottles:
        return '🍾';
      case DisposalCategory.cans:
        return '🥫';
      case DisposalCategory.cartons:
        return '📦';
      case DisposalCategory.unusedClothes:
        return '👕';
      case DisposalCategory.glass:
        return '🍷';
    }
  }

  String get value {
    return toString().split('.').last;
  }

  static DisposalCategory fromString(String value) {
    return DisposalCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DisposalCategory.plasticBottles,
    );
  }
}
