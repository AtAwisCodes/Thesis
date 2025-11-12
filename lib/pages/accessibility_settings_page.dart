import 'package:flutter/material.dart';
import 'package:rexplore/utilities/responsive_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilitySettingsPage extends StatefulWidget {
  const AccessibilitySettingsPage({super.key});

  @override
  State<AccessibilitySettingsPage> createState() =>
      _AccessibilitySettingsPageState();
}

class _AccessibilitySettingsPageState extends State<AccessibilitySettingsPage> {
  double _textScaleFactor = 1.0;
  bool _highContrastMode = false;
  bool _reducedMotion = false;
  bool _largeTouchTargets = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _textScaleFactor = prefs.getDouble('textScaleFactor') ?? 1.0;
        _highContrastMode = prefs.getBool('highContrastMode') ?? false;
        _reducedMotion = prefs.getBool('reducedMotion') ?? false;
        _largeTouchTargets = prefs.getBool('largeTouchTargets') ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTextScale(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('textScaleFactor', value);
    setState(() {
      _textScaleFactor = value;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Text size updated. Restart app to apply changes.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveHighContrast(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('highContrastMode', value);
    setState(() {
      _highContrastMode = value;
    });
  }

  Future<void> _saveReducedMotion(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reducedMotion', value);
    setState(() {
      _reducedMotion = value;
    });
  }

  Future<void> _saveLargeTouchTargets(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('largeTouchTargets', value);
    setState(() {
      _largeTouchTargets = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = context.responsive;
    final textHelper = ResponsiveText(responsive);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Accessibility'),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibility'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: responsive.spacing(16)),
        children: [
          // Header Info
          Padding(
            padding: EdgeInsets.symmetric(horizontal: responsive.spacing(16)),
            child: Container(
              padding: EdgeInsets.all(responsive.spacing(16)),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(responsive.borderRadius(12)),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.accessibility_new_rounded,
                    color: Colors.blue,
                    size: responsive.iconSize(32),
                  ),
                  SizedBox(width: responsive.spacing(12)),
                  Expanded(
                    child: Text(
                      'Customize the app to better suit your needs',
                      style: textHelper.bodyMedium(context),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: responsive.spacing(24)),

          // Text Size Section
          _buildSectionHeader(context, 'Display'),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: responsive.spacing(16)),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(responsive.borderRadius(12)),
              ),
              child: Padding(
                padding: EdgeInsets.all(responsive.spacing(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.text_fields_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(width: responsive.spacing(12)),
                        Text(
                          'Text Size',
                          style: textHelper.titleMedium(context).copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    SizedBox(height: responsive.spacing(16)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'A',
                          style: TextStyle(
                            fontSize: responsive.fontSize(12),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _textScaleFactor,
                            min: 0.8,
                            max: 1.5,
                            divisions: 7,
                            label: '${(_textScaleFactor * 100).round()}%',
                            onChanged: (value) {
                              _saveTextScale(value);
                            },
                          ),
                        ),
                        Text(
                          'A',
                          style: TextStyle(
                            fontSize: responsive.fontSize(24),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Current size: ${(_textScaleFactor * 100).round()}%',
                      style: textHelper.bodySmall(context).copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                    SizedBox(height: responsive.spacing(8)),
                    Container(
                      padding: EdgeInsets.all(responsive.spacing(12)),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.5),
                        borderRadius:
                            BorderRadius.circular(responsive.borderRadius(8)),
                      ),
                      child: Text(
                        'Sample Text: This is how text will appear in the app.',
                        style: TextStyle(
                          fontSize: 14 * _textScaleFactor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: responsive.spacing(16)),

          // High Contrast Mode
          _buildSwitchTile(
            context: context,
            icon: Icons.contrast_rounded,
            title: 'High Contrast Mode',
            subtitle: 'Increase color contrast for better visibility',
            value: _highContrastMode,
            onChanged: _saveHighContrast,
          ),

          // Interaction Section
          SizedBox(height: responsive.spacing(8)),
          _buildSectionHeader(context, 'Interaction'),

          _buildSwitchTile(
            context: context,
            icon: Icons.motion_photos_off_rounded,
            title: 'Reduce Motion',
            subtitle: 'Minimize animations and transitions',
            value: _reducedMotion,
            onChanged: _saveReducedMotion,
          ),

          _buildSwitchTile(
            context: context,
            icon: Icons.touch_app_rounded,
            title: 'Large Touch Targets',
            subtitle: 'Increase button and interactive element sizes',
            value: _largeTouchTargets,
            onChanged: _saveLargeTouchTargets,
          ),

          SizedBox(height: responsive.spacing(24)),

          // Reset Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: responsive.spacing(16)),
            child: OutlinedButton.icon(
              onPressed: () {
                _showResetDialog(context);
              },
              icon: const Icon(Icons.restore_rounded),
              label: const Text('Reset to Defaults'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  vertical: responsive.spacing(12),
                ),
              ),
            ),
          ),

          SizedBox(height: responsive.spacing(16)),

          // Info Note
          Padding(
            padding: EdgeInsets.symmetric(horizontal: responsive.spacing(16)),
            child: Container(
              padding: EdgeInsets.all(responsive.spacing(12)),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(responsive.borderRadius(8)),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: responsive.iconSize(20),
                  ),
                  SizedBox(width: responsive.spacing(8)),
                  Expanded(
                    child: Text(
                      'Some settings may require restarting the app to take full effect.',
                      style: textHelper.bodySmall(context).copyWith(
                            color: Colors.orange.shade900,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: responsive.spacing(24)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final responsive = context.responsive;
    final textHelper = ResponsiveText(responsive);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        responsive.spacing(16),
        responsive.spacing(8),
        responsive.spacing(16),
        responsive.spacing(12),
      ),
      child: Text(
        title.toUpperCase(),
        style: textHelper.labelLarge(context).copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final theme = Theme.of(context);
    final responsive = context.responsive;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(16),
        vertical: responsive.spacing(4),
      ),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
        ),
        child: SwitchListTile(
          secondary: Container(
            padding: EdgeInsets.all(responsive.spacing(8)),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(responsive.borderRadius(8)),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: responsive.iconSize(24),
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(subtitle),
          value: value,
          onChanged: onChanged,
          contentPadding: EdgeInsets.symmetric(
            horizontal: responsive.spacing(16),
            vertical: responsive.spacing(8),
          ),
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    final responsive = context.responsive;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.restore_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Reset Settings'),
          ],
        ),
        content: const Text(
          'This will reset all accessibility settings to their default values. Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveTextScale(1.0);
              await _saveHighContrast(false);
              await _saveReducedMotion(false);
              await _saveLargeTouchTargets(false);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings reset to defaults'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
        ),
      ),
    );
  }
}
