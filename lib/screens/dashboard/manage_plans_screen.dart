import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../state/gym_data_provider.dart';
import '../../models/plan_model.dart';

// 🚀 IMPORTED: Global Refresh Decorator Widget
import '../../core/widgets/app_refresh_wrapper.dart';

class ManagePlansScreen extends StatefulWidget {
  const ManagePlansScreen({super.key});

  @override
  State<ManagePlansScreen> createState() => _ManagePlansScreenState();
}

class _ManagePlansScreenState extends State<ManagePlansScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationValueController = TextEditingController();
  String _durationTypeSelection = 'months';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationValueController.dispose();
    super.dispose();
  }

  // Displays a clean bottom sheet modal to create new plan assets
  void _showAddPlanBottomSheet(BuildContext context, GymDataProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.cardRadius)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24,
          left: 16,
          right: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create New Plan Package',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Plan Name *',
                hintText: 'e.g. Quarterly Gold Roster',
                controller: _nameController,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Price (INR) *',
                      hintText: '0.00',
                      keyboardType: TextInputType.number,
                      controller: _priceController,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Duration Value *',
                      hintText: 'e.g. 3',
                      keyboardType: TextInputType.number,
                      controller: _durationValueController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Duration Type *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                  border: Border.all(color: AppTheme.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _durationTypeSelection,
                    isExpanded: true,
                    items: ['days', 'weeks', 'months', 'years'].map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _durationTypeSelection = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              StatefulBuilder(
                builder: (context, setModalState) {
                  return PrimaryButton(
                    text: 'Deploy Plan Package',
                    isLoading: _isSaving,
                    onPressed: () async {
                      if (_nameController.text.trim().isEmpty ||
                          _priceController.text.isEmpty ||
                          _durationValueController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('All fields marked with an asterisk are required.')),
                        );
                        return;
                      }

                      setModalState(() => _isSaving = true);

                      final newPlan = Plan(
                        id: 0,
                        gymId: provider.selectedGymId,
                        name: _nameController.text.trim(),
                        price: double.tryParse(_priceController.text) ?? 0.0,
                        durationValue: int.tryParse(_durationValueController.text) ?? 1,
                        durationType: _durationTypeSelection,
                      );

                      bool success = await provider.addNewPlan(newPlan);

                      setModalState(() => _isSaving = false);

                      if (mounted) {
                        Navigator.pop(context);
                        _nameController.clear();
                        _priceController.clear();
                        _durationValueController.clear();
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Plan package saved successfully.' : 'Failed to save plan details.'),
                            backgroundColor: success ? AppTheme.success : AppTheme.danger,
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GymDataProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Manage Plan Matrices', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        leading: const BackButton(color: AppTheme.textPrimary),
      ),
      // 🚀 APPLIED: Universal refresh component wrapper over primary body viewports
      body: provider.activePlans.isEmpty
          ? const AppRefreshWrapper(
              child: Center(
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Text(
                    'No membership tiers active in this workspace branch.', 
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ),
            )
          : AppRefreshWrapper(
              child: ListView.separated(
                // 🛡️ CRITICAL: Enforces physical drag bounds even on short list lengths
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: provider.activePlans.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  final plan = provider.activePlans[idx];
                  
                  final int activeUserCount = provider.activeMembers.where((member) {
                    return member.status == 'ACTIVE' && 
                           (member.membershipNumber ?? '').toLowerCase() == plan.name.toLowerCase();
                  }).length;

                  return AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(plan.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                            const SizedBox(height: 4),
                            Text(
                              'Duration: ${plan.durationValue} ${plan.durationType}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '👥 $activeUserCount Active Members',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary),
                              ),
                            )
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${plan.price.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.primary),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.textSecondary),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.danger),
                                  onPressed: () {},
                                ),
                              ],
                            )
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onPressed: () => _showAddPlanBottomSheet(context, provider),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}