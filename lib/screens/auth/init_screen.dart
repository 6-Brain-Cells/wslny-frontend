import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';

/// First screen shown on app start. Checks stored auth and redirects
/// to home if logged in, otherwise to language selection.
class InitScreen extends StatefulWidget {
  const InitScreen({super.key});

  @override
  State<InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuthAndNavigate());
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();
    if (!mounted) return;
    final route = authProvider.isAuthenticated
        ? AppRoutes.mainLayout
        : AppRoutes.signIn;
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
