import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core Framework & Reusable Components
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';

// State and Entity Data Models
import '../../state/gym_data_provider.dart';
import '../../models/member_model.dart';
import '../../models/plan_model.dart';

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  String _genderSelection = 'Male';
  bool _isSaving = false;

  // Track dynamic plan properties explicitly
  Plan? _selectedPlan;
  bool _isCustomPlan = false;

  // State Controllers to handle input field processing
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _membershipIdController = TextEditingController();
  final TextEditingController _planDetailsController = TextEditingController();
  final TextEditingController _joiningDateController = TextEditingController();
  final TextEditingController _totalPriceController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  double _calculatedDueAmount = 0.0;

  @override
  void initState() {
    super.initState();
    // UX Autofill: Initialize with today's date formatted perfectly for PostgreSQL
    _joiningDateController.text = DateTime.now().toIso8601String().substring(0, 10);

    // Bind real-time computational drivers to look out for raw currency calculations
    _totalPriceController.addListener(_computeDues);
    _paidAmountController.addListener(_computeDues);
  }

  void _computeDues() {
    final double total = double.tryParse(_totalPriceController.text) ?? 0.0;
    final double paid = double.tryParse(_paidAmountController.text) ?? 0.0;
    setState(() {
      _calculatedDueAmount = (total - paid) < 0 ? 0.0 : (total - paid);
    });
  }

  @override
  void dispose() {
    _totalPriceController.removeListener(_computeDues);
    _paidAmountController.removeListener(_computeDues);
    _nameController.dispose();
    _phoneController.dispose();
    _membershipIdController.dispose();
    _planDetailsController.dispose();
    _joiningDateController.dispose();
    _totalPriceController.dispose();
    _paidAmountController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<GymDataProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Add Member Roster Entry', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        leading: const BackButton(color: AppTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(label: 'Full Name *', hintText: 'Enter complete legal identity', controller: _nameController),
            const SizedBox(height: 12),

            // 🚀 Selection Form Cell: Dynamic Gym Plan Dropdown Matrix
            const Text('Gym Membership Plan *', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Plan?>(
                  value: _isCustomPlan ? null : _selectedPlan,
                  hint: Text(_isCustomPlan ? 'Custom Plan Configuration' : 'Choose an active plan tier...'),
                  isExpanded: true,
                  items: [
                    ...dataProvider.activePlans.map((Plan plan) {
                      return DropdownMenuItem<Plan?>(
                        value: plan,
                        child: Text('${plan.name} (₹${plan.price.toStringAsFixed(0)} • ${plan.durationValue} ${plan.durationType})'),
                      );
                    }),
                    const DropdownMenuItem<Plan?>(
                      value: null, // Triggers a fallback custom parameter allocation override row
                      child: Text('⚠️ Custom Override (Enter manual values)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    )
                  ],
                  onChanged: (Plan? planChoice) {
                    setState(() {
                      if (planChoice == null) {
                        _isCustomPlan = true;
                        _selectedPlan = null;
                        _planDetailsController.text = "Custom";
                        _totalPriceController.text = "";
                        _paidAmountController.text = "";
                      } else {
                        _isCustomPlan = false;
                        _selectedPlan = planChoice;
                        _planDetailsController.text = planChoice.name;
                        _totalPriceController.text = planChoice.price.toStringAsFixed(0);
                        _paidAmountController.text = ""; // Force fresh tracking calculations
                      }
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            AppTextField(
              label: 'Plan Details Label', 
              hintText: 'Select plan above or define description here', 
              controller: _planDetailsController,
              enabled: _isCustomPlan, // Field locks tight if catalog model item is selected
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Total Plan Price *', 
                    hintText: '0.00', 
                    keyboardType: TextInputType.number, 
                    controller: _totalPriceController,
                    enabled: _isCustomPlan,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Paid Amount Collected *', 
                    hintText: '0.00', 
                    keyboardType: TextInputType.number, 
                    controller: _paidAmountController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 🎨 Mathematical Layout Renderer: Inline Outstanding Due Value Display Screen
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Row(
                children: [
                  const Text('Calculated Due Balance: ', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  Text(
                    '₹${_calculatedDueAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13, 
                      fontWeight: FontWeight.bold, 
                      color: _calculatedDueAmount > 0 ? AppTheme.danger : AppTheme.success
                    ),
                  ),
                ],
              ),
            ),

            const Text('Gender Select', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            Row(
              children: ['Male', 'Female', 'Other'].map((g) {
                return Row(
                  children: [
                    Radio<String>(
                      value: g,
                      groupValue: _genderSelection,
                      activeColor: AppTheme.primary,
                      onChanged: (val) {
                        if (val != null) setState(() => _genderSelection = val);
                      },
                    ),
                    Text(g, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 12),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            AppTextField(label: 'Mobile Phone Number *', hintText: '+91 XXXXX XXXXX', keyboardType: TextInputType.phone, controller: _phoneController),
            const SizedBox(height: 12),
            AppTextField(label: 'Assign Gym Membership ID', hintText: 'MEM-2026-XXXX', controller: _membershipIdController),
            const SizedBox(height: 12),
            AppTextField(label: 'Joining Date', hintText: 'YYYY-MM-DD', controller: _joiningDateController),
            const SizedBox(height: 12),
            AppTextField(label: 'Email Address (Optional)', hintText: 'client@domain.com', keyboardType: TextInputType.emailAddress, controller: _emailController),
            const SizedBox(height: 12),
            AppTextField(label: 'Date of Birth (DOB)', hintText: 'YYYY-MM-DD', controller: _dobController),
            const SizedBox(height: 12),
            AppTextField(label: 'Physical Home Address', hintText: 'Street, City, State', controller: _addressController),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Save Member Portfolio',
              isLoading: _isSaving, 
              onPressed: () async {
                // strict validation blocking logic
                if (_nameController.text.trim().isEmpty || 
                    _phoneController.text.trim().isEmpty ||
                    _totalPriceController.text.isEmpty ||
                    _paidAmountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill out all mandatory fields marked with an asterisk (*).'),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                  return;
                }

                setState(() => _isSaving = true);
                
                final newMemberRecord = Member(
                  id: 0, 
                  gymId: dataProvider.selectedGymId,
                  // 🚀 FIXED: Store the selected plan name securely so the app can link relationships
                  membershipNumber: _planDetailsController.text.trim(), 
                  name: _nameController.text.trim(),
                  phone: _phoneController.text.trim(),
                  gender: _genderSelection,
                  email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
                  address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
                  joinedDate: DateTime.tryParse(_joiningDateController.text) ?? DateTime.now(),
                  dueAmount: _calculatedDueAmount,
                  status: 'ACTIVE',
                );

                bool isSaved = await dataProvider.registerNewMember(newMemberRecord);

                if (!mounted) return;
                setState(() => _isSaving = false);

                if (isSaved) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile saved successfully onto production cloud database server.'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to save profile. Please check server endpoint availability.'),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}