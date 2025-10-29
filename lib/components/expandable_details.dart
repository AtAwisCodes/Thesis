import 'package:flutter/material.dart';

class ExpandableDetails extends StatefulWidget {
  final String title;
  final String details;
  final int? viewCount;
  final String? uploadedAt;
  final int maxLinesCollapsed;
  final TextStyle? titleStyle;
  final TextStyle? detailsStyle;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final Widget? actionButton;

  const ExpandableDetails({
    super.key,
    required this.title,
    required this.details,
    this.viewCount,
    this.uploadedAt,
    this.maxLinesCollapsed = 2,
    this.titleStyle,
    this.detailsStyle,
    this.backgroundColor,
    this.padding,
    this.actionButton,
  });

  @override
  State<ExpandableDetails> createState() => _ExpandableDetailsState();
}

class _ExpandableDetailsState extends State<ExpandableDetails>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  bool _isTextOverflowing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Check if text will overflow after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTextOverflow();
    });
  }

  @override
  void didUpdateWidget(ExpandableDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.details != widget.details ||
        oldWidget.maxLinesCollapsed != widget.maxLinesCollapsed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkTextOverflow();
      });
    }
  }

  void _checkTextOverflow() {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: widget.details,
        style: widget.detailsStyle ??
            TextStyle(
              fontSize: 14,
              color:
                  Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black,
              height: 1.4,
            ),
      ),
      maxLines: widget.maxLinesCollapsed,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: MediaQuery.of(context).size.width - 48);

    if (mounted) {
      setState(() {
        _isTextOverflowing = textPainter.didExceedMaxLines;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultTextColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: widget.padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.backgroundColor ??
            (theme.brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.grey[200]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // View count and date row (if provided) with optional action button
          if (widget.viewCount != null ||
              widget.uploadedAt != null ||
              widget.actionButton != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (widget.viewCount != null) ...[
                          Icon(
                            Icons.visibility,
                            size: 16,
                            color: defaultTextColor.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatViewCount(widget.viewCount!)} views',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: defaultTextColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                        if (widget.viewCount != null &&
                            widget.uploadedAt != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '•',
                              style: TextStyle(
                                color: defaultTextColor.withOpacity(0.7),
                              ),
                            ),
                          ),
                        if (widget.uploadedAt != null)
                          Text(
                            widget.uploadedAt!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: defaultTextColor.withOpacity(0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.actionButton != null) widget.actionButton!,
                ],
              ),
            ),

          // Details text
          GestureDetector(
            onTap: _isTextOverflowing ? _toggleExpanded : null,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.details,
                    maxLines: _isExpanded ? null : widget.maxLinesCollapsed,
                    overflow: _isExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: widget.detailsStyle ??
                        TextStyle(
                          fontSize: 14,
                          color: defaultTextColor,
                          height: 1.4,
                        ),
                  ),
                  // Only show more/less button if text overflows
                  if (_isTextOverflowing) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _isExpanded ? 'Show less' : '...more',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.primaryColor,
                          ),
                        ),
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 18,
                          color: theme.primaryColor,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatViewCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
