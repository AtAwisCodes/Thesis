import 'package:flutter/material.dart';
import 'package:rexplore/utilities/responsive_helper.dart';
import 'package:rexplore/constants/about_us_content.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = context.responsive;
    final textHelper = ResponsiveText(responsive);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsive.spacing(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(responsive.spacing(16)),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius:
                    BorderRadius.circular(responsive.borderRadius(12)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.description_rounded,
                    size: responsive.iconSize(32),
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: responsive.spacing(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Terms of Service',
                          style: textHelper.titleLarge(context).copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Last updated: November 2025',
                          style: textHelper.bodySmall(context).copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: responsive.spacing(24)),

            // Introduction
            _buildSection(
              context,
              responsive,
              textHelper,
              title: '1. Introduction',
              content:
                  'Welcome to ${AboutUsContent.appName}. By accessing or using our mobile application, you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use our application.',
            ),

            // Acceptance of Terms
            _buildSection(
              context,
              responsive,
              textHelper,
              title: '2. Acceptance of Terms',
              content:
                  'By creating an account and using ${AboutUsContent.appName}, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions, as well as our Privacy Policy.',
            ),

            // User Accounts
            _buildSection(
              context,
              responsive,
              textHelper,
              title: '3. User Accounts',
              content:
                  'You are responsible for maintaining the confidentiality of your account credentials. You agree to:\n\n'
                  '• Provide accurate and complete information during registration\n'
                  '• Keep your password secure and confidential\n'
                  '• Notify us immediately of any unauthorized access\n'
                  '• Be responsible for all activities under your account',
            ),

            // Use of Services
            _buildSection(
              context,
              responsive,
              textHelper,
              title: '4. Use of Services',
              content:
                  '${AboutUsContent.appName} provides AI-powered recycling identification and AR educational features. You agree to:\n\n'
                  '• Use the service only for lawful purposes\n'
                  '• Not upload inappropriate or harmful content\n'
                  '• Not attempt to reverse engineer or hack the application\n'
                  '• Respect intellectual property rights\n'
                  '• Follow community guidelines',
            ),

            // Content and Intellectual Property
            _buildSection(
              context,
              responsive,
              textHelper,
              title: '5. Content & Intellectual Property',
              content:
                  'All content, features, and functionality of ${AboutUsContent.appName} are owned by us and are protected by copyright, trademark, and other intellectual property laws.\n\n'
                  'User-generated content remains your property, but you grant us a license to use, display, and distribute it within the application.',
            ),

            // AI and Image Recognition
            _buildSection(
              context,
              responsive,
              textHelper,
              title: '6. AI & Image Recognition',
              content:
                  'Our AI-powered image recognition provides recycling suggestions based on available data. While we strive for accuracy:\n\n'
                  '• Results are suggestions, not guarantees\n'
                  '• Always verify with local recycling guidelines\n'
                  '• We are not liable for incorrect classifications\n'
                  '• Local regulations may vary',
            ),

            // Disclaimer
            _buildSection(
              context,
              responsive,
              textHelper,
              title: '7. Disclaimer of Warranties',
              content:
                  '${AboutUsContent.appName} is provided "as is" without warranties of any kind. We do not guarantee:\n\n'
                  '• Uninterrupted or error-free service\n'
                  '• Complete accuracy of information\n'
                  '• Fitness for a particular purpose\n'
                  '• Compatibility with all devices',
            ),

            // Limitation of Liability
            _buildSection(
              context,
              responsive,
              textHelper,
              title: '8. Limitation of Liability',
              content:
                  'To the maximum extent permitted by law, ${AboutUsContent.appName} shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the application.',
            ),

            // Termination
            _buildSection(
              context,
              responsive,
              textHelper,
              title: '9. Termination',
              content:
                  'We reserve the right to terminate or suspend your account at any time for violations of these terms. You may also delete your account at any time through the app settings.',
            ),

            // Changes to Terms
            _buildSection(
              context,
              responsive,
              textHelper,
              title: '10. Changes to Terms',
              content:
                  'We may update these Terms and Conditions from time to time. We will notify users of significant changes through the application. Continued use after changes constitutes acceptance of the new terms.',
            ),

            // Governing Law
            _buildSection(
              context,
              responsive,
              textHelper,
              title: '11. Governing Law',
              content:
                  'These terms shall be governed by and construed in accordance with applicable laws, without regard to conflict of law principles.',
            ),

            // Contact
            _buildSection(
              context,
              responsive,
              textHelper,
              title: '12. Contact Information',
              content:
                  'If you have questions about these Terms and Conditions, please contact us at:\n\n'
                  '${AboutUsContent.contactEmail}',
            ),

            SizedBox(height: responsive.spacing(24)),

            // Agreement Notice
            Container(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.blue,
                    size: responsive.iconSize(24),
                  ),
                  SizedBox(width: responsive.spacing(12)),
                  Expanded(
                    child: Text(
                      'By using ${AboutUsContent.appName}, you acknowledge that you have read and understood these Terms and Conditions and agree to be bound by them.',
                      style: textHelper.bodyMedium(context).copyWith(
                            color: Colors.blue.shade900,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: responsive.spacing(16)),

            // Copyright
            Center(
              child: Text(
                AboutUsContent.copyright,
                style: textHelper.bodySmall(context).copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
              ),
            ),

            SizedBox(height: responsive.spacing(24)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    ResponsiveHelper responsive,
    ResponsiveText textHelper, {
    required String title,
    required String content,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: responsive.spacing(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textHelper.titleMedium(context).copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: responsive.spacing(8)),
          Text(
            content,
            style: textHelper.bodyMedium(context).copyWith(
                  height: 1.6,
                ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
