import 'package:flutter/material.dart';
import 'package:wslny/screens/MainLayout.dart';
import 'package:wslny/screens/pages/chatbot_page.dart';
import 'package:wslny/screens/pages/profile_page.dart';
import 'package:wslny/screens/pages/rewards_page.dart';
import '../screens/auth/language_selection_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';

class AppRoutes {
  static const String languageSelection = '/';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String mainLayout = '/main';
  static const String chatbot = '/chatbot';
  static const String profile = '/profile';
  static const String routeOptions = '/route-options';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case languageSelection:
        return MaterialPageRoute(
          builder: (_) => const LanguageSelectionScreen(),
        );
      case signIn:
        return MaterialPageRoute(builder: (_) => const SignInScreen());
      case signUp:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case mainLayout:
        return MaterialPageRoute(builder: (_) => const MainLayout());
      case chatbot:
        return MaterialPageRoute(builder: (_) => const ChatbotPage());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case routeOptions:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: RewardsPage(),
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
