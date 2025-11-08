import 'disposal_categories.dart';

/// Comprehensive disposal information for each category
/// Based on environmental best practices and recycling standards

class DisposalInfo {
  final DisposalCategory category;
  final String title;
  final String description;
  final List<String> steps;
  final List<String> dosList;
  final List<String> dontsList;
  final String environmentalImpact;
  final String funFact;

  DisposalInfo({
    required this.category,
    required this.title,
    required this.description,
    required this.steps,
    required this.dosList,
    required this.dontsList,
    required this.environmentalImpact,
    required this.funFact,
  });
}

class DisposalGuideService {
  static final Map<DisposalCategory, DisposalInfo> _guides = {
    DisposalCategory.plasticBottles: DisposalInfo(
      category: DisposalCategory.plasticBottles,
      title: 'How to Properly Dispose Plastic Bottles',
      description:
          'Plastic bottles are one of the most recyclable items. When disposed properly, they can be transformed into new products like clothing, furniture, and even new bottles.',
      steps: [
        'Empty the bottle completely and rinse with water',
        'Remove caps and labels (these are often different types of plastic)',
        'Crush or flatten the bottle to save space',
        'Place in your recycling bin or take to a recycling center',
        'Check local recycling symbols - look for #1 (PETE) or #2 (HDPE)',
      ],
      dosList: [
        'Rinse bottles to remove residue',
        'Check the recycling number on the bottom',
        'Separate caps from bottles',
        'Crush bottles to save space',
        'Use refillable bottles when possible',
      ],
      dontsList: [
        'Don\'t throw caps in with bottles',
        'Don\'t include bottles with food residue',
        'Don\'t mix with non-recyclable plastics',
        'Avoid crushing bottles if your local facility prefers them whole',
        'Don\'t burn plastic bottles',
      ],
      environmentalImpact:
          '1 recycled plastic bottle saves enough energy to power a lightbulb for 3 hours. Recycling prevents 450 years of decomposition time in landfills.',
      funFact: 'It takes about 25 recycled bottles to make one fleece jacket!',
    ),
    DisposalCategory.cans: DisposalInfo(
      category: DisposalCategory.cans,
      title: 'How to Properly Dispose Cans',
      description:
          'Aluminum and steel cans are infinitely recyclable. They\'re one of the most valuable recyclables and have the highest recycling rate.',
      steps: [
        'Empty the can completely and rinse out residue',
        'No need to remove labels - they burn off during recycling',
        'You can leave cans whole or crush them (check local preference)',
        'Place in your recycling bin',
        'For steel cans, a magnet will stick to them - they\'re also recyclable',
      ],
      dosList: [
        'Rinse cans before recycling',
        'Recycle both aluminum and steel cans',
        'Include soda cans, soup cans, and food cans',
        'Crush cans to save space if local facility allows',
        'Return cans to deposit programs where available',
      ],
      dontsList: [
        'Don\'t include cans with food residue',
        'Don\'t recycle aerosol cans unless completely empty',
        'Don\'t mix paint cans with regular cans',
        'Don\'t include damaged or rusted cans in some programs',
        'Don\'t throw in trash - cans are highly valuable',
      ],
      environmentalImpact:
          'Recycling one aluminum can saves enough energy to run a TV for 3 hours. Aluminum can be recycled endlessly without quality loss, and recycled cans return to shelves in just 60 days!',
      funFact:
          'The aluminum can is the most recycled beverage container in the world!',
    ),
    DisposalCategory.cartons: DisposalInfo(
      category: DisposalCategory.cartons,
      title: 'How to Properly Dispose Cartons',
      description:
          'Cartons (milk, juice, soup boxes) are made from paper, plastic, and aluminum layers. They require special recycling processes but are accepted in many programs.',
      steps: [
        'Empty the carton completely',
        'Rinse out any remaining liquid or food',
        'Flatten the carton to save space',
        'Replace the cap if your program requires it',
        'Check if your local recycling accepts cartons - most modern facilities do',
      ],
      dosList: [
        'Rinse cartons thoroughly',
        'Flatten to save space in recycling bin',
        'Include milk cartons, juice boxes, and soup cartons',
        'Check local guidelines for caps',
        'Look for the carton recycling symbol',
      ],
      dontsList: [
        'Don\'t include cartons with heavy food contamination',
        'Don\'t throw away - they\'re recyclable in most areas',
        'Don\'t cut or tear cartons unnecessarily',
        'Don\'t assume all cartons are the same - check local rules',
        'Don\'t include wax-coated cartons if not accepted locally',
      ],
      environmentalImpact:
          'Recycling cartons saves trees and reduces landfill waste. One ton of recycled cartons saves 7,000 gallons of water and prevents 5 cubic yards of landfill space.',
      funFact:
          'Cartons can be recycled into tissues, paper towels, and even building materials!',
    ),
    DisposalCategory.unusedClothes: DisposalInfo(
      category: DisposalCategory.unusedClothes,
      title: 'How to Properly Dispose Unused Clothes',
      description:
          'Textiles are highly reusable and recyclable. Only 15% of clothing is currently recycled, but there are many options for responsible disposal.',
      steps: [
        'Sort clothes into: wearable, damaged but repairable, and too damaged',
        'Donate wearable clothes to charities, thrift stores, or shelters',
        'Use textile recycling bins for damaged clothing',
        'Repurpose old clothes as cleaning rags or craft materials',
        'Some brands offer take-back programs for their products',
      ],
      dosList: [
        'Wash and clean clothes before donating',
        'Donate to local charities or thrift stores',
        'Use textile recycling bins for unwearable items',
        'Consider clothing swaps with friends',
        'Sell valuable items online or at consignment shops',
        'Repurpose into cleaning cloths, quilts, or pet bedding',
      ],
      dontsList: [
        'Don\'t throw clothes in regular trash',
        'Don\'t donate heavily stained or torn items to charities',
        'Don\'t leave donations outside in bad weather',
        'Don\'t donate clothes with broken zippers unless noted',
        'Don\'t burn synthetic fabrics - releases toxins',
      ],
      environmentalImpact:
          'The fashion industry produces 10% of global carbon emissions. Donating or recycling clothes extends their life, saving water, energy, and reducing landfill waste. One donated shirt saves 700 gallons of water!',
      funFact:
          'It takes 2,700 liters of water to make one cotton t-shirt - that\'s enough drinking water for one person for 2.5 years!',
    ),
  };

  /// Get disposal information for a specific category
  static DisposalInfo? getDisposalInfo(DisposalCategory category) {
    return _guides[category];
  }

  /// Get disposal information by string value
  static DisposalInfo? getDisposalInfoByString(String categoryValue) {
    final category = DisposalCategoryExtension.fromString(categoryValue);
    return _guides[category];
  }

  /// Get all categories
  static List<DisposalCategory> getAllCategories() {
    return DisposalCategory.values;
  }

  /// Get formatted trivia text for video player
  static String getTriviaText(DisposalCategory category) {
    final info = _guides[category];
    if (info == null) return '';

    return '''
${info.title}

${info.description}

Steps to Dispose:
${info.steps.map((step) => '• $step').join('\n')}

DO:
${info.dosList.take(3).map((item) => '• $item').join('\n')}

DON'T:
${info.dontsList.take(3).map((item) => '• $item').join('\n')}

${info.environmentalImpact}

${info.funFact}
''';
  }

  static String getShortTrivia(DisposalCategory category) {
    final info = _guides[category];
    if (info == null) return '';

    return '''
${info.title}

${info.description}

${info.environmentalImpact}

${info.funFact}
''';
  }
}
