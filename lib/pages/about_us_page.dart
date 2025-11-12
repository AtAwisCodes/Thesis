import 'package:flutter/material.dart';
import 'package:rexplore/constants/about_us_content.dart';
import 'package:rexplore/utilities/responsive_helper.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = context.responsive;
    final textHelper = ResponsiveText(responsive);

    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section with Logo
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(responsive.spacing(24)),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.teal],
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
                  // App Logo
                  Container(
                    padding: EdgeInsets.all(responsive.spacing(16)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'lib/icons/ReXplore.png',
                      width: responsive.screenWidth * 0.2,
                      height: responsive.screenWidth * 0.2,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(16)),
                  // App Name
                  Text(
                    AboutUsContent.appName,
                    style: textHelper.headlineMedium(context).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: responsive.spacing(8)),
                  // Tagline
                  Text(
                    AboutUsContent.tagline,
                    style: textHelper.bodyLarge(context).copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Description Section
            Padding(
              padding: EdgeInsets.all(responsive.spacing(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About ReXplore',
                    style: textHelper.headlineSmall(context).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: responsive.spacing(12)),
                  Text(
                    AboutUsContent.description,
                    style: textHelper.bodyLarge(context),
                    textAlign: TextAlign.justify,
                  ),
                  SizedBox(height: responsive.spacing(24)),

                  // Mission
                  _buildInfoCard(
                    context,
                    responsive,
                    textHelper,
                    icon: Icons.flag_rounded,
                    title: 'Our Mission',
                    content: AboutUsContent.mission,
                    color: Colors.blue,
                  ),
                  SizedBox(height: responsive.spacing(16)),

                  // Vision
                  _buildInfoCard(
                    context,
                    responsive,
                    textHelper,
                    icon: Icons.visibility_rounded,
                    title: 'Our Vision',
                    content: AboutUsContent.vision,
                    color: Colors.purple,
                  ),
                  SizedBox(height: responsive.spacing(24)),

                  // Features Section
                  Text(
                    'Key Features',
                    style: textHelper.headlineSmall(context).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: responsive.spacing(16)),
                  ...AboutUsContent.features.map(
                    (feature) => _buildFeatureCard(
                      context,
                      responsive,
                      textHelper,
                      feature,
                    ),
                  ),

                  SizedBox(height: responsive.spacing(24)),

                  // Technologies Section
                  Text(
                    'Built With',
                    style: textHelper.headlineSmall(context).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: responsive.spacing(12)),
                  Wrap(
                    spacing: responsive.spacing(8),
                    runSpacing: responsive.spacing(8),
                    children: AboutUsContent.technologies
                        .map(
                          (tech) => Chip(
                            label: Text(tech),
                            backgroundColor:
                                theme.colorScheme.primary.withOpacity(0.1),
                            labelStyle: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                        .toList(),
                  ),

                  SizedBox(height: responsive.spacing(24)),

                  // Contact & Info Section
                  Container(
                    padding: EdgeInsets.all(responsive.spacing(16)),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.3),
                      borderRadius:
                          BorderRadius.circular(responsive.borderRadius(12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          context,
                          responsive,
                          textHelper,
                          Icons.code_rounded,
                          'Developed by',
                          AboutUsContent.developedBy,
                        ),
                        SizedBox(height: responsive.spacing(8)),
                        _buildInfoRow(
                          context,
                          responsive,
                          textHelper,
                          Icons.info_rounded,
                          'Version',
                          AboutUsContent.version,
                        ),
                        SizedBox(height: responsive.spacing(8)),
                        _buildInfoRow(
                          context,
                          responsive,
                          textHelper,
                          Icons.email_rounded,
                          'Contact',
                          AboutUsContent.contactEmail,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: responsive.spacing(24)),

                  // Disclaimer
                  Container(
                    padding: EdgeInsets.all(responsive.spacing(16)),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(responsive.borderRadius(12)),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: responsive.iconSize(20),
                        ),
                        SizedBox(width: responsive.spacing(12)),
                        Expanded(
                          child: Text(
                            AboutUsContent.disclaimer,
                            style: textHelper.bodySmall(context).copyWith(
                                  color: Colors.orange.shade900,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: responsive.spacing(24)),

                  // Copyright
                  Center(
                    child: Text(
                      AboutUsContent.copyright,
                      style: textHelper.bodySmall(context).copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ),
                  SizedBox(height: responsive.spacing(16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    ResponsiveHelper responsive,
    ResponsiveText textHelper, {
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(responsive.spacing(16)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: responsive.iconSize(24)),
              SizedBox(width: responsive.spacing(8)),
              Text(
                title,
                style: textHelper.titleMedium(context).copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(12)),
          Text(
            content,
            style: textHelper.bodyMedium(context),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    ResponsiveHelper responsive,
    ResponsiveText textHelper,
    Feature feature,
  ) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.only(bottom: responsive.spacing(12)),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
      ),
      child: Padding(
        padding: EdgeInsets.all(responsive.spacing(16)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(responsive.spacing(8)),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(responsive.borderRadius(8)),
              ),
              child: Text(
                feature.icon,
                style: TextStyle(fontSize: responsive.fontSize(24)),
              ),
            ),
            SizedBox(width: responsive.spacing(16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.title,
                    style: textHelper.titleMedium(context).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: responsive.spacing(4)),
                  Text(
                    feature.description,
                    style: textHelper.bodyMedium(context).copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    ResponsiveHelper responsive,
    ResponsiveText textHelper,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: responsive.iconSize(18),
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        SizedBox(width: responsive.spacing(8)),
        Text(
          '$label: ',
          style: textHelper.bodyMedium(context).copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: textHelper.bodyMedium(context),
          ),
        ),
      ],
    );
  }
}
