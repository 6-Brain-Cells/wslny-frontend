import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wslny/l10n/app_localizations.dart';
import 'package:wslny/providers/language_provider.dart';
import 'package:wslny/widgets/common/bottom_nav_bar.dart';
import 'package:wslny/screens/pages/map_home_page.dart';
import 'package:wslny/screens/pages/favorites_page.dart';
import 'package:wslny/screens/pages/profile_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final _pages = const [
    MapHomePage(),
    FavoritesPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageProvider = context.watch<LanguageProvider>();
    final isRTL = languageProvider.isArabic;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,

        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            final slide = Tween<Offset>(
              begin: Offset(isRTL ? -0.1 : 0.1, 0),
              end: Offset.zero,
            ).animate(animation);

            return SlideTransition(
              position: slide,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: _pages[_currentIndex],
        ),
        bottomNavigationBar: Directionality(
          textDirection: TextDirection.ltr,
          child: BottomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            l10n: l10n,
          ),
        ),
      ),
    );
  }
}
