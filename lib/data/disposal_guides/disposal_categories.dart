/// Disposal Categories and Information System
/// Contains comprehensive guides for proper waste disposal

enum DisposalCategory {
  plasticBottles,
  tires,
  rubberBands,
  cans,
  cartons,
  paper,
  unusedClothes,
}

extension DisposalCategoryExtension on DisposalCategory {
  String get name {
    switch (this) {
      case DisposalCategory.plasticBottles:
        return 'Plastic Bottles';
      case DisposalCategory.tires:
        return 'Tires';
      case DisposalCategory.rubberBands:
        return 'Rubber Bands';
      case DisposalCategory.cans:
        return 'Cans';
      case DisposalCategory.cartons:
        return 'Cartons';
      case DisposalCategory.paper:
        return 'Paper';
      case DisposalCategory.unusedClothes:
        return 'Unused Clothes';
    }
  }

  String get icon {
    switch (this) {
      case DisposalCategory.plasticBottles:
        return '🍾';
      case DisposalCategory.tires:
        return '🛞';
      case DisposalCategory.rubberBands:
        return '⭕';
      case DisposalCategory.cans:
        return '🥫';
      case DisposalCategory.cartons:
        return '📦';
      case DisposalCategory.paper:
        return '📄';
      case DisposalCategory.unusedClothes:
        return '👕';
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
