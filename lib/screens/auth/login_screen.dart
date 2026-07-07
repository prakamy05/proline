import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import '../../state/gym_data_provider.dart'; 
import '../../core/theme/app_theme.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/app_text_field.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _preferredLanguage = 'English';
  bool _isAuthenticating = false;

  void _executeMockLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;

    setState(() => _isAuthenticating = true);
    final dataProvider = Provider.of<GymDataProvider>(context, listen: false);
    
    bool isAuthorized = await dataProvider.loginWorkspace(
      _emailController.text.trim(),
      _passwordController.text,
    );

    // ⚠️ CRITICAL GUARD: If login succeeds, the reactive router in main.dart unmounts 
    // this widget instantly. We must exit immediately to avoid a defunct setState() crash!
    if (!mounted) return;

    setState(() => _isAuthenticating = false);

    // If still mounted and authentication failed, show the error alert
    if (!isAuthorized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication denied. Please verify credentials.'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius - 4),
                    ),
                    child: const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'ProLine',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing * 1.5),
              AppTextField(
                label: 'Business Email Address',
                hintText: 'name@workspace.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Password',
                hintText: '••••••••',
                controller: _passwordController,
                isPassword: true,
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'Next',
                isLoading: _isAuthenticating,
                onPressed: _executeMockLogin,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                  ),
                ),
                onPressed: () {},
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.g_mobiledata_rounded, color: AppTheme.textPrimary, size: 28),
                    SizedBox(width: 4),
                    Text(
                      'Sign in with Google',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    );
                  },
                  child: const Text(
                    "Don't have a workspace? Complete Sign Up",
                    style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.help_outline_rounded, size: 16, color: AppTheme.textSecondary),
                    label: const Text('Help & Support', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ),
                  DropdownButton<String>(
                    value: _preferredLanguage,
                    underline: const SizedBox(),
                    items: ['English', 'Spanish', 'Hindi'].map((String lang) {
                      return DropdownMenuItem<String>(
                        value: lang,
                        child: Text(lang, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _preferredLanguage = val);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}