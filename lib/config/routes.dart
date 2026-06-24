import 'package:flutter/material.dart';
import 'package:wslny/screens/MainLayout.dart';
import 'package:wslny/screens/pages/chatbot_page.dart';
import 'package:wslny/screens/pages/profile_page.dart';
import 'package:wslny/screens/pages/rewards_page.dart';
import 'package:wslny/screens/pages/route_results_page.dart';
import '../screens/auth/init_screen.dart';
import '../screens/auth/language_selection_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../models/route_models.dart';

class AppRoutes {
  static const String init = '/init';
  static const String languageSelection = '/';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String mainLayout = '/main';
  static const String chatbot = '/chatbot';
  static const String profile = '/profile';
  static const String routeOptions = '/route-options';
  static const String routeResults = '/route-results';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case init:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const InitScreen(),
        );
      case languageSelection:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LanguageSelectionScreen(),
        );
      case signIn:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SignInScreen(),
        );
      case signUp:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SignUpScreen(),
        );
      case mainLayout:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MainLayout(),
        );
      case chatbot:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ChatbotPage(),
        );
      case profile:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ProfilePage(),
        );
      case routeOptions:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const Scaffold(
            body: RewardsPage(),
          ),
        );
      case routeResults:
        final routeResponse = settings.arguments as RouteResponse?;
        if (routeResponse == null) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const Scaffold(
              body: Center(child: Text('Route data not found')),
            ),
          );
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => RouteResultsPage(routeResponse: routeResponse),
        );
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
