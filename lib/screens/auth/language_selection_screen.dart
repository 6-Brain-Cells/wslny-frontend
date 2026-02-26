import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/language_provider.dart';
import '../../widgets/common/language_button.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  /// True when opened from profile (user already authenticated).
  static bool isFromProfile(BuildContext context) {
    return ModalRoute.of(context)?.settings.arguments == true;
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final fromProfile = isFromProfile(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              
              // App Logo/Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Icon(
                    Icons.translate,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                l10n.chooseLanguage,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Subtitle
              Text(
                l10n.selectYourPreferredLanguage,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              
              const Spacer(flex: 2),
              
              // Language Buttons
              LanguageButton(
                languageCode: 'US',
                languageName: l10n.english,
                onTap: () async {
                  await languageProvider.setLanguage(AppConstants.englishCode);
                  if (context.mounted) {
                    if (fromProfile) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacementNamed(context, AppRoutes.signIn);
                    }
                  }
                },
              ),
              
              const SizedBox(height: 16),
              
              LanguageButton(
                languageCode: 'EG',
                languageName: l10n.arabic,
                onTap: () async {
                  await languageProvider.setLanguage(AppConstants.arabicCode);
                  if (context.mounted) {
                    if (fromProfile) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacementNamed(context, AppRoutes.signIn);
                    }
                  }
                },
              ),
              
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
