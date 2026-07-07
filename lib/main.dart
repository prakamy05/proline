import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'state/gym_data_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/bottom_nav_layout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => GymDataProvider(),
      child: const ProLineSaaS(),
    ),
  );
}

class ProLineSaaS extends StatelessWidget {
  const ProLineSaaS({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProLine SaaS Workspace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LandingRouter(),
    );
  }
}

class LandingRouter extends StatefulWidget {
  const LandingRouter({super.key});

  @override
  State<LandingRouter> createState() => _LandingRouterState();
}

class _LandingRouterState extends State<LandingRouter> {
  @override
  void initState() {
    super.initState();
    // Fire the async security storage lookup safely after the initial build frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GymDataProvider>(context, listen: false).trySilentAutoLogin();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GymDataProvider>(
      builder: (context, provider, child) {
        // 1. If the app is actively reading encrypted hardware keys, hold the splash view
        if (provider.isCheckingSession) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }

        // 2. Storage lookup complete: check if a valid session exists in memory
        if (provider.isAuthenticated) {
          return const BottomNavLayout();
        }

        // 3. Fallback: No session found or server verification failed, show login screen
        return const LoginScreen();
      },
    );
  }
}