import 'package:flutter/material.dart';
import 'package:rexplore/data/disposal_guides/disposal_categories.dart';

/// Widget for selecting disposal category during video upload
class CategorySelectorWidget extends StatefulWidget {
  final DisposalCategory? initialCategory;
  final Function(DisposalCategory) onCategorySelected;

  const CategorySelectorWidget({
    super.key,
    this.initialCategory,
    required this.onCategorySelected,
  });

  @override
  State<CategorySelectorWidget> createState() => _CategorySelectorWidgetState();
}

class _CategorySelectorWidgetState extends State<CategorySelectorWidget> {
  DisposalCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Disposal Category',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose the category that best describes your video content. This will provide viewers with proper disposal information.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DisposalCategory.values.map((category) {
            final isSelected = _selectedCategory == category;
            return FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category.icon,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 4),
                  Text(category.name),
                ],
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? category : null;
                });
                if (selected) {
                  widget.onCategorySelected(category);
                }
              },
              selectedColor: Colors.green.shade100,
              checkmarkColor: Colors.green,
            );
          }).toList(),
        ),
        if (_selectedCategory != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Category selected: ${_selectedCategory!.name}. Disposal information will be shown to viewers.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Dropdown version for compact spaces
class CategoryDropdownSelector extends StatelessWidget {
  final DisposalCategory? selectedCategory;
  final Function(DisposalCategory?) onChanged;

  const CategoryDropdownSelector({
    super.key,
    this.selectedCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<DisposalCategory>(
      value: selectedCategory,
      decoration: InputDecoration(
        labelText: 'Disposal Category',
        hintText: 'Select category',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: DisposalCategory.values.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Row(
            children: [
              Text(category.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(category.name),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null) {
          return 'Please select a disposal category';
        }
        return null;
      },
    );
  }
}
