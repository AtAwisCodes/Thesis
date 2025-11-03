import 'package:flutter/material.dart';
import 'package:rexplore/data/disposal_guides/disposal_categories.dart';
import 'package:rexplore/data/disposal_guides/disposal_info_data.dart';

/// Widget to display disposal information in the video player trivia section
class DisposalTriviaWidget extends StatefulWidget {
  final DisposalCategory category;
  final bool showFullInfo;

  const DisposalTriviaWidget({
    super.key,
    required this.category,
    this.showFullInfo = true,
  });

  @override
  State<DisposalTriviaWidget> createState() => _DisposalTriviaWidgetState();
}

class _DisposalTriviaWidgetState extends State<DisposalTriviaWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final info = DisposalGuideService.getDisposalInfo(widget.category);

    if (info == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact Header
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xff5BEC84).withOpacity(0.15),
                const Color(0xff5BEC84).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xff5BEC84).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  widget.category.icon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 10),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff2D6A4F),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Disposal Guide',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Compact description
        Text(
          info.description,
          style: const TextStyle(fontSize: 12, height: 1.4),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),

        // Compact info boxes
        _buildCompactInfoBox(
          icon: Icons.eco_outlined,
          title: 'Impact',
          content: info.environmentalImpact,
          color: const Color(0xff5BEC84),
        ),
        const SizedBox(height: 8),
        _buildCompactInfoBox(
          icon: Icons.lightbulb_outline,
          title: 'Tip',
          content: info.funFact,
          color: Colors.orange,
        ),

        // Expandable detailed info
        if (widget.showFullInfo) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xff5BEC84).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isExpanded
                        ? Icons.remove_circle_outline
                        : Icons.add_circle_outline,
                    color: const Color(0xff2D6A4F),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isExpanded ? 'Less Details' : 'More Details',
                    style: const TextStyle(
                      color: Color(0xff2D6A4F),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (_isExpanded) ...[
            const SizedBox(height: 12),
            _buildCompactStepsList('Steps', info.steps),
            const SizedBox(height: 12),
            _buildCompactCheckList('Do\'s ✓', info.dosList, true),
            const SizedBox(height: 10),
            _buildCompactCheckList('Don\'ts ✗', info.dontsList, false),
          ],
        ],
      ],
    );
  }

  Widget _buildCompactInfoBox({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStepsList(String title, List<String> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xff2D6A4F),
          ),
        ),
        const SizedBox(height: 6),
        ...steps.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xff5BEC84),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.value,
                    style: const TextStyle(fontSize: 11, height: 1.4),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCompactCheckList(
      String title, List<String> items, bool isPositive) {
    final color = isPositive ? const Color(0xff5BEC84) : Colors.red.shade400;
    final icon = isPositive ? Icons.check_circle : Icons.cancel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 11, height: 1.3),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}

/// Compact version for small spaces
class CompactDisposalTrivia extends StatelessWidget {
  final DisposalCategory category;

  const CompactDisposalTrivia({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final shortTrivia = DisposalGuideService.getShortTrivia(category);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(category.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              const Text(
                'Disposal Tip',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            shortTrivia,
            style: const TextStyle(fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}
