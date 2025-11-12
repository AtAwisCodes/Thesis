import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rexplore/pages/terms_conditions_page.dart';
import 'package:rexplore/pages/help_support_page.dart';
import 'package:rexplore/services/ThemeProvider.dart';
import 'package:rexplore/services/report_service.dart';
import 'package:rexplore/utilities/responsive_helper.dart';
import 'package:rexplore/constants/about_us_content.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    } catch (e) {
      setState(() {
        _appVersion = AboutUsContent.version;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = context.responsive;
    final textHelper = ResponsiveText(responsive);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: responsive.spacing(8)),
        children: [
          // Appearance Section
          _buildSectionHeader(context, 'Appearance'),
          _buildSettingsTile(
            context: context,
            icon: Icons.brightness_6_rounded,
            title: 'Theme Mode',
            subtitle: Provider.of<ThemeProvider>(context).isDarkMode
                ? 'Dark'
                : 'Light',
            trailing: Switch(
              value: Provider.of<ThemeProvider>(context).isDarkMode,
              onChanged: (val) {
                Provider.of<ThemeProvider>(context, listen: false)
                    .toggleTheme(val);
              },
            ),
            onTap: null,
          ),

          // Support Section
          _buildSectionHeader(context, 'Support'),
          _buildSettingsTile(
            context: context,
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            subtitle: 'FAQs, contact us, tutorials',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpSupportPage(),
                ),
              );
            },
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.feedback_outlined,
            title: 'Send Feedback',
            subtitle: 'Report bugs or suggest features',
            onTap: () {
              _showFeedbackDialog(context);
            },
          ),

          // Legal Section
          _buildSectionHeader(context, 'Legal'),
          _buildSettingsTile(
            context: context,
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            subtitle: 'Terms of service',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsConditionsPage(),
                ),
              );
            },
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'How we handle your data',
            onTap: () {
              _showPrivacyDialog(context);
            },
          ),

          // About Section
          _buildSectionHeader(context, 'About'),
          _buildSettingsTile(
            context: context,
            icon: Icons.info_outline_rounded,
            title: 'App Version',
            subtitle: _appVersion.isEmpty ? 'Loading...' : _appVersion,
            trailing: _appVersion.isEmpty
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  )
                : null,
            onTap: () {
              _showAppInfoDialog(context);
            },
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.developer_mode_rounded,
            title: 'Developed By',
            subtitle: AboutUsContent.developedBy,
            onTap: null,
          ),

          SizedBox(height: responsive.spacing(16)),

          // Copyright footer
          Center(
            child: Padding(
              padding: EdgeInsets.all(responsive.spacing(16)),
              child: Text(
                AboutUsContent.copyright,
                style: textHelper.bodySmall(context).copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
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
        responsive.spacing(24),
        responsive.spacing(16),
        responsive.spacing(8),
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

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final responsive = context.responsive;

    return ListTile(
      leading: Container(
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
      trailing: trailing ??
          (onTap != null
              ? Icon(
                  Icons.chevron_right_rounded,
                  size: responsive.iconSize(24),
                )
              : null),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(16),
        vertical: responsive.spacing(4),
      ),
    );
  }

  void _showAppInfoDialog(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = context.responsive;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Image.asset(
              'lib/icons/ReXplore.png',
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 12),
            const Text('App Info'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('App Name', AboutUsContent.appName),
            const SizedBox(height: 8),
            _buildInfoRow('Version', _appVersion),
            const SizedBox(height: 8),
            _buildInfoRow('Developer', AboutUsContent.developedBy),
            const SizedBox(height: 16),
            Text(
              AboutUsContent.tagline,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const Text(': '),
        Expanded(child: Text(value)),
      ],
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final responsive = context.responsive;
    final feedbackController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Send Feedback'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Help us improve ReXplore by sharing your thoughts!'),
              const SizedBox(height: 16),
              TextField(
                controller: feedbackController,
                enabled: !isSubmitting,
                maxLines: 5,
                maxLength: 1000,
                decoration: const InputDecoration(
                  hintText: 'Type your feedback here...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final feedback = feedbackController.text.trim();
                      if (feedback.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter your feedback'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      setState(() => isSubmitting = true);

                      try {
                        final reportService = ReportService();
                        final success = await reportService.submitFeedback(
                          feedback: feedback,
                        );

                        if (context.mounted) {
                          Navigator.pop(context);

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.white),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Thank you for your feedback!',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 3),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Failed to submit feedback. Please try again.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              icon: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(isSubmitting ? 'Sending...' : 'Send'),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
          ),
        ),
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    final responsive = context.responsive;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Your privacy is important to us. This privacy policy explains how ReXplore collects, uses, and protects your personal information.\n\n'
            '1. Information We Collect\n'
            '- Account information (email, name)\n'
            '- Usage data and preferences\n'
            '- Uploaded images for recycling identification\n\n'
            '2. How We Use Your Information\n'
            '- To provide and improve our services\n'
            '- To personalize your experience\n'
            '- To communicate with you\n\n'
            '3. Data Security\n'
            'We implement security measures to protect your information.\n\n'
            '4. Your Rights\n'
            'You have the right to access, modify, or delete your data at any time.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
        ),
      ),
    );
  }
}
