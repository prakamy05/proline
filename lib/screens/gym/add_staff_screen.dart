import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../state/gym_data_provider.dart';

class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({super.key});

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _roleController = TextEditingController();
  final _salaryController = TextEditingController();

  bool _isSaving = false;

  // 🛡️ Staff Permission Flags Initial Configuration States
  final Map<String, bool> _permissions = {
    'manage_members': true,
    'manage_plans': false,
    'mark_attendance': true,
    'view_member_analytics': false,
    'view_finance': false,
    'download_reports': false,
  };

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  void _submitStaffForm(GymDataProvider provider) async {
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Staff Name and Phone Number are required fields.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    bool success = await provider.registerStaffMember(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      role: _roleController.text.trim().isEmpty ? 'Trainer' : _roleController.text.trim(),
      salary: double.tryParse(_salaryController.text) ?? 0.0,
      permissions: _permissions,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Staff member registered successfully!' : 'Failed to save staff configurations.'),
          backgroundColor: success ? AppTheme.success : AppTheme.danger,
        ),
      );
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GymDataProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Add Workspace Employee', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        leading: const BackButton(color: AppTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(label: 'Full Legal Name *', hintText: 'John Doe', controller: _nameController),
              const SizedBox(height: 12),
              AppTextField(label: 'Mobile Phone No *', hintText: '+91 98765 43210', keyboardType: TextInputType.phone, controller: _phoneController),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: AppTextField(label: 'Assigned Role', hintText: 'Head Trainer', controller: _roleController)),
                  const SizedBox(width: 12),
                  Expanded(child: AppTextField(label: 'Base Salary (₹/mo)', hintText: '25000', keyboardType: TextInputType.number, controller: _salaryController)),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Assign Access Permissions Matrix', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              const Text('Define what tools this staff account can see or manipulate.', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              const SizedBox(height: 12),
              
              Card(
                color: AppTheme.cardBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.border)),
                elevation: 0,
                child: Column(
                  children: _permissions.keys.map((String key) {
                    final cleanTitle = key.replaceAll('_', ' ').toUpperCase();
                    return CheckboxListTile(
                      activeColor: AppTheme.primary,
                      title: Text(cleanTitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      value: _permissions[key],
                      onChanged: (bool? val) {
                        if (val != null) setState(() => _permissions[key] = val);
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Pre-Register Staff Account',
                isLoading: _isSaving,
                onPressed: () => _submitStaffForm(provider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}