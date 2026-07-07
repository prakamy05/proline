import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../state/gym_data_provider.dart';
import '../dashboard/bottom_nav_layout.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _gymNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _preferredLanguage = 'English';
  bool _isRegistering = false;
  bool _isStaffSelected = false; // 🚀 Dynamic identity state toggle tracker

  @override
  void dispose() {
    _gymNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _executeRegistration() async {
    // 🛡️ Input Validation Guard Block Adaptively Checked
    if ((!_isStaffSelected && _gymNameController.text.trim().isEmpty) ||
        _ownerNameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required account setup fields.'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    setState(() => _isRegistering = true);
    
    final dataProvider = Provider.of<GymDataProvider>(context, listen: false);
    bool registrationSuccess = await dataProvider.registerNewWorkspace(
      isStaff: _isStaffSelected,
      gymName: _isStaffSelected ? "" : _gymNameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isRegistering = false);

    if (registrationSuccess) {
      // 🧑‍💼 Double checks if newly registered staff member is unlinked on the ecosystem
      if (dataProvider.isUnlinkedStaff) {
        _showUnlinkedStaffDialog();
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const BottomNavLayout()),
          (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isStaffSelected 
              ? 'Registration denied. Your phone number might not be added by an owner yet.' 
              : 'Registration denied. Email may exist or server is unreachable.'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  void _showUnlinkedStaffDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
            SizedBox(width: 8),
            Text('Account Pending Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Your profile has been created successfully! However, your mobile number has not been linked to a live club branch roster by an owner yet. Please ask your administrator to register your phone number to gain dashboard access.',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close Dialog
              Navigator.pop(context); // Return out to Login Base Gateway Screen
            },
            child: const Text('Understood', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppTheme.textPrimary),
      ),
      body: SafeArea(
        child: WidgetLifecycles(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Join ProLine System',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Set up your organizational tenancy profile or access your assigned workspace.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 20),
                
                // 🚀 ROLE ADAPTIVE CONTROLLER SWITCH SEGMENT
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _isStaffSelected = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !_isStaffSelected ? AppTheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Gym Owner',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: !_isStaffSelected ? Colors.white : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _isStaffSelected = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _isStaffSelected ? AppTheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Staff Member',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _isStaffSelected ? Colors.white : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
          
                // 🚀 ADAPTIVE RENDERING NODE: Hides Gym Name field dynamically when Staff registration is active
                if (!_isStaffSelected) ...[
                  AppTextField(
                    label: 'Gym Name *', 
                    hintText: 'Iron Core Fitness Ltd',
                    controller: _gymNameController,
                  ),
                  const SizedBox(height: 12),
                ],
                AppTextField(
                  label: _isStaffSelected ? 'Your Name *' : 'Your Name (Owner Name) *', 
                  hintText: 'Alex Rivera',
                  controller: _ownerNameController,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Mobile No (with country code) *', 
                  hintText: '+91 98765 43210', 
                  keyboardType: TextInputType.phone,
                  controller: _phoneController,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Email Address *', 
                  hintText: 'name@workspace.com', 
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Password (Create) *', 
                  hintText: '••••••••', 
                  isPassword: true,
                  controller: _passwordController,
                ),
                const SizedBox(height: AppTheme.spacing),
                PrimaryButton(
                  text: 'Sign Up',
                  isLoading: _isRegistering,
                  onPressed: _executeRegistration,
                ),
                const SizedBox(height: AppTheme.spacing),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.help_outline_rounded, size: 16, color: AppTheme.textSecondary),
                      label: const Text('Help and Support', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
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
                const SizedBox(height: AppTheme.padding),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Minimal placeholder helper to wrap content seamlessly
class WidgetLifecycles extends StatelessWidget {
  final Widget child;
  const WidgetLifecycles({super.key, required this.child});
  @override
  Widget build(BuildContext context) => child;
}