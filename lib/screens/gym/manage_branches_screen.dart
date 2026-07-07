import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/app_refresh_wrapper.dart';
import '../../state/gym_data_provider.dart';

class ManageBranchesScreen extends StatefulWidget {
  const ManageBranchesScreen({super.key});

  @override
  State<ManageBranchesScreen> createState() => _ManageBranchesScreenState();
}

class _ManageBranchesScreenState extends State<ManageBranchesScreen> {
  final _branchNameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _branchNameController.dispose();
    super.dispose();
  }

  void _showAddBranchModal(BuildContext context, GymDataProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.cardRadius))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24, left: 16, right: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Provision New Franchise Branch', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Creates an isolated workspace node with independent members, plans, and ledgers.', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Branch Location / Name *',
              hintText: 'e.g., ProLine Gym - Connaught Place',
              controller: _branchNameController,
            ),
            const SizedBox(height: 20),
            StatefulBuilder(
              builder: (context, setModalState) => PrimaryButton(
                text: 'Deploy Location Node',
                isLoading: _isSaving,
                onPressed: () async {
                  if (_branchNameController.text.trim().isEmpty) return;
                  setModalState(() => _isSaving = true);

                  bool success = await provider.deployNewFranchiseBranch(_branchNameController.text.trim());
                  setModalState(() => _isSaving = false);

                  if (mounted) {
                    Navigator.pop(context);
                    _branchNameController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Branch initialized! Switched to new workspace.' : 'Failed to launch branch.'),
                        backgroundColor: success ? AppTheme.success : AppTheme.danger,
                      ),
                    );
                    if (success) Navigator.pop(context); 
                  }
                },
              ),
            )
          ],
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
        title: const Text('Workspace Branches Matrix', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        leading: const BackButton(color: AppTheme.textPrimary),
      ),
      body: AppRefreshWrapper(
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: provider.clientGyms.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, idx) {
            final gym = provider.clientGyms[idx];
            final bool isActive = gym.id == provider.selectedGymId;

            return InkWell(
              onTap: () async {
                if (!isActive) {
                  await provider.changeBranch(gym.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Switched focus context branch to ${gym.name}'), backgroundColor: AppTheme.primary),
                    );
                    Navigator.pop(context);
                  }
                }
              },
              child: AppCard(
                border: isActive ? const BorderSide(color: AppTheme.primary, width: 1.5) : null,
                color: isActive ? AppTheme.primary.withValues(alpha: 0.01) : AppTheme.cardBg,
                child: Row(
                  children: [
                    Icon(Icons.storefront_rounded, color: isActive ? AppTheme.primary : AppTheme.textSecondary, size: 20),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(gym.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isActive ? AppTheme.primary : AppTheme.textPrimary)),
                          Text('Branch ID ref: #${gym.id}', style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                        child: const Text('ACTIVE FOCUS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                      )
                    else
                      const Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.textSecondary),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: AppTheme.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.buttonRadius)),
            ),
            onPressed: () => _showAddBranchModal(context, provider),
            icon: const Icon(Icons.add, size: 16, color: AppTheme.primary),
            label: const Text('Add New Franchise Branch Location', style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}