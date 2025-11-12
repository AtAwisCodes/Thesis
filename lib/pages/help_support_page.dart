import 'package:flutter/material.dart';
import 'package:rexplore/utilities/responsive_helper.dart';
import 'package:rexplore/constants/about_us_content.dart';
import 'package:rexplore/services/report_service.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = context.responsive;
    final textHelper = ResponsiveText(responsive);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(responsive.spacing(24)),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.cyan],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(responsive.borderRadius(30)),
                  bottomRight: Radius.circular(responsive.borderRadius(30)),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.help_outline_rounded,
                    size: responsive.iconSize(64),
                    color: Colors.white,
                  ),
                  SizedBox(height: responsive.spacing(16)),
                  Text(
                    'How Can We Help?',
                    style: textHelper.headlineMedium(context).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: responsive.spacing(8)),
                  Text(
                    'Find answers to common questions or reach out to us',
                    style: textHelper.bodyMedium(context).copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: responsive.spacing(24)),

            // Quick Actions
            Padding(
              padding: EdgeInsets.symmetric(horizontal: responsive.spacing(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: textHelper.titleLarge(context).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: responsive.spacing(16)),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          context,
                          responsive,
                          icon: Icons.email_outlined,
                          title: 'Email Us',
                          color: Colors.orange,
                          onTap: () => _sendEmail(context),
                        ),
                      ),
                      SizedBox(width: responsive.spacing(12)),
                      Expanded(
                        child: _buildQuickActionCard(
                          context,
                          responsive,
                          icon: Icons.bug_report_outlined,
                          title: 'Report Bug',
                          color: Colors.red,
                          onTap: () => _reportBug(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: responsive.spacing(32)),

            // FAQ Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: responsive.spacing(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frequently Asked Questions',
                    style: textHelper.titleLarge(context).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: responsive.spacing(16)),
                  _buildFAQItem(
                    context,
                    responsive,
                    textHelper,
                    question: 'How does the AI image recognition work?',
                    answer:
                        'Our AI uses advanced machine learning models trained on thousands of recyclable items. Simply take a photo of an item, and the AI will identify it and provide recycling instructions.',
                  ),
                  _buildFAQItem(
                    context,
                    responsive,
                    textHelper,
                    question: 'What is Augmented Reality (AR) mode?',
                    answer:
                        'AR mode allows you to view 3D models of recyclable items in your real environment. Point your camera at a surface and place virtual recycling items to learn about them interactively.',
                  ),
                  _buildFAQItem(
                    context,
                    responsive,
                    textHelper,
                    question: 'How accurate is the recycling information?',
                    answer:
                        'We strive for high accuracy, but recycling rules vary by location. Always check with your local recycling center for specific guidelines. Our app provides general best practices.',
                  ),
                  _buildFAQItem(
                    context,
                    responsive,
                    textHelper,
                    question: 'How do I change my profile picture?',
                    answer:
                        'Go to your Profile page (bottom navigation), tap on your profile picture, and select a new image from your gallery or take a new photo.',
                  ),
                  _buildFAQItem(
                    context,
                    responsive,
                    textHelper,
                    question: 'How can I save items to favorites?',
                    answer:
                        'When viewing any video or recycling information, tap the heart icon to add it to your favorites. Access your saved items from the Favorites tab in the bottom navigation.',
                  ),
                  _buildFAQItem(
                    context,
                    responsive,
                    textHelper,
                    question: 'Is my data safe and private?',
                    answer:
                        'Yes! We take privacy seriously. Your data is encrypted and stored securely. We never share your personal information with third parties. Read our Privacy Policy for details.',
                  ),
                  _buildFAQItem(
                    context,
                    responsive,
                    textHelper,
                    question: 'How do I delete my account?',
                    answer:
                        'You can delete your account from the Profile page. Note that this action is permanent and cannot be undone. All your data will be removed from our servers.',
                  ),
                  _buildFAQItem(
                    context,
                    responsive,
                    textHelper,
                    question:
                        'The app is not working properly. What should I do?',
                    answer:
                        'Try these steps:\n1. Force close and restart the app\n2. Check for app updates in the store\n3. Clear app cache in Settings\n4. Restart your device\n5. If issues persist, report the bug using the "Report Bug" button above.',
                  ),
                  _buildFAQItem(
                    context,
                    responsive,
                    textHelper,
                    question: 'Can I contribute recycling information?',
                    answer:
                        'Yes! Use the Upload page to share recycling tips, guides, or interesting content about sustainability. Help build a community of eco-conscious individuals.',
                  ),
                ],
              ),
            ),

            SizedBox(height: responsive.spacing(32)),

            // Contact Section
            Container(
              margin: EdgeInsets.all(responsive.spacing(16)),
              padding: EdgeInsets.all(responsive.spacing(20)),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius:
                    BorderRadius.circular(responsive.borderRadius(16)),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.contact_support_rounded,
                    size: responsive.iconSize(48),
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(height: responsive.spacing(16)),
                  Text(
                    'Still Need Help?',
                    style: textHelper.titleLarge(context).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: responsive.spacing(8)),
                  Text(
                    'Our support team is here to help you',
                    style: textHelper.bodyMedium(context),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: responsive.spacing(16)),
                  ElevatedButton.icon(
                    onPressed: () => _sendEmail(context),
                    icon: const Icon(Icons.email_rounded),
                    label: const Text('Contact Support'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.spacing(24),
                        vertical: responsive.spacing(12),
                      ),
                    ),
                  ),
                  SizedBox(height: responsive.spacing(12)),
                  Text(
                    AboutUsContent.contactEmail,
                    style: textHelper.bodySmall(context).copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ),

            SizedBox(height: responsive.spacing(24)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    ResponsiveHelper responsive, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
        child: Padding(
          padding: EdgeInsets.all(responsive.spacing(16)),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(responsive.spacing(12)),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: responsive.iconSize(32),
                ),
              ),
              SizedBox(height: responsive.spacing(12)),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(
    BuildContext context,
    ResponsiveHelper responsive,
    ResponsiveText textHelper, {
    required String question,
    required String answer,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: responsive.spacing(12)),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(
            horizontal: responsive.spacing(16),
            vertical: responsive.spacing(8),
          ),
          childrenPadding: EdgeInsets.fromLTRB(
            responsive.spacing(16),
            0,
            responsive.spacing(16),
            responsive.spacing(16),
          ),
          leading: Icon(
            Icons.help_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            question,
            style: textHelper.bodyLarge(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          children: [
            Text(
              answer,
              style: textHelper.bodyMedium(context).copyWith(
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: AboutUsContent.contactEmail,
      query: 'subject=ReXplore Support Request',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Email: ${AboutUsContent.contactEmail}'),
              action: SnackBarAction(
                label: 'Copy',
                onPressed: () {
                  // TODO: Implement copy to clipboard
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open email app: $e')),
        );
      }
    }
  }

  void _reportBug(BuildContext context) {
    final bugController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.bug_report, color: Colors.red),
              SizedBox(width: 8),
              Text('Report a Bug'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please describe the issue you\'re experiencing:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bugController,
                enabled: !isSubmitting,
                maxLines: 5,
                maxLength: 1000,
                decoration: const InputDecoration(
                  hintText:
                      'Example: The app crashes when I try to upload an image...',
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
                      final bugDescription = bugController.text.trim();
                      if (bugDescription.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please describe the bug'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      setState(() => isSubmitting = true);

                      try {
                        final reportService = ReportService();
                        final success = await reportService.submitBugReport(
                          bugDescription: bugDescription,
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
                                        'Bug report submitted. Thank you!',
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
                                    'Failed to submit bug report. Please try again.'),
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
              label: Text(isSubmitting ? 'Submitting...' : 'Submit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
