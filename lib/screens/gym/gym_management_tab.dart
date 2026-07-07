import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Core Framework & Reusable Components
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/app_refresh_wrapper.dart';

// State and Entity Data Models
import '../../state/gym_data_provider.dart';
import '../../models/gym_model.dart';

// Operations View Screens
import 'package:proline/screens/dashboard/manage_plans_screen.dart';
import 'package:proline/screens/gym/add_staff_screen.dart'; // 🚀 IMPORTED: Missing target operational view screen reference

class GymManagementTab extends StatefulWidget {
  const GymManagementTab({super.key});

  @override
  State<GymManagementTab> createState() => _GymManagementTabState();
}

class _GymManagementTabState extends State<GymManagementTab> {
  bool _isEditingProfile = false;
  final _storage = const FlutterSecureStorage();

  // Track state drivers explicitly
  late TextEditingController _gymNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _gymNameController = TextEditingController();
    _ownerNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _loadStoredDetails();
  }

  // Asynchronously fetch extra cached parameters
  void _loadStoredDetails() async {
    final email = await _storage.read(key: "owner_email") ?? "admin@proline.io";
    final phone = await _storage.read(key: "owner_phone") ?? "+91 98765 43210";
    if (mounted && !_isEditingProfile) {
      setState(() {
        _emailController.text = email;
        _phoneController.text = phone;
      });
    }
  }

  @override
  void dispose() {
    _gymNameController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showQrAttendanceStation(BuildContext context, int gymId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
          title: const Text(
            'Attendance Terminal Station',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.border, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.qr_code_2_rounded, size: 140, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 14),
              Text(
                'Active Workspace Access Token: GYM_ID_$gymId',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Scan this terminal QR code using a mobile device to automatically process check-in attendance records instantly.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close Station Terminal', style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<GymDataProvider>(context);

    // 🛡️ Resolve current gym name matching selectedGymId parameter
    final currentGym = dataProvider.clientGyms.firstWhere(
      (g) => g.id == dataProvider.selectedGymId,
      orElse: () => Gym(id: dataProvider.selectedGymId, ownerId: 0, name: "Main Workspace Brand"),
    );

    // 🔄 Sync raw model inputs onto text controllers dynamically
    if (!_isEditingProfile) {
      _gymNameController.text = currentGym.name;
      _ownerNameController.text = dataProvider.ownerName ?? "Workspace Owner Profile";
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AppRefreshWrapper(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Branch Identity & Workspace Profile'),
              AppCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
                          child: const Icon(Icons.person_rounded, color: AppTheme.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {},
                            style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                            icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                            label: const Text('Change Photo', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        IconButton(
                          icon: Icon(_isEditingProfile ? Icons.close_rounded : Icons.edit_rounded, size: 18, color: AppTheme.primary),
                          onPressed: () => setState(() => _isEditingProfile = !_isEditingProfile),
                        )
                      ],
                    ),
                    const Divider(color: AppTheme.border, height: 20),
                    if (!_isEditingProfile) ...[
                      _profileLine('Gym / Branch Name', _gymNameController.text),
                      _profileLine('Owner / Staff Identity', _ownerNameController.text),
                      _profileLine('Corporate Email', _emailController.text),
                      _profileLine('Phone Contact Number', _phoneController.text),
                    ] else ...[
                      AppTextField(label: 'Gym/Branch Name', controller: _gymNameController),
                      const SizedBox(height: 8),
                      AppTextField(label: 'Owner Name', controller: _ownerNameController),
                      const SizedBox(height: 8),
                      AppTextField(label: 'Email', controller: _emailController),
                      const SizedBox(height: 8),
                      AppTextField(label: 'Phone Number', controller: _phoneController),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        text: 'Save Identity Changes',
                        onPressed: () => setState(() => _isEditingProfile = false),
                      )
                    ]
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing),

              _sectionLabel('SaaS Subscription License Matrix'),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ProLine ${dataProvider.saasPlanName} Tier Framework', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                          child: const Text('ACTIVE', style: TextStyle(color: AppTheme.success, fontSize: 8, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const Divider(color: AppTheme.border, height: 16),
                    _profileLine('Time Remaining', '${dataProvider.saasDaysRemaining} Operational Days Left'),
                    _profileLine('Expiry Date', dataProvider.saasExpiryDate.isEmpty ? 'N/A' : dataProvider.saasExpiryDate),
                    const SizedBox(height: 8),
                    PrimaryButton(
                      text: 'Upgrade License To Enterprise Pro+',
                      backgroundColor: AppTheme.primary,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _sectionLabel('Gym Membership Plan Configurations'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManagePlansScreen()),
                      );
                    },
                    child: const Text(
                      'Manage System Plans', 
                      style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.assignment_outlined, size: 18, color: AppTheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${dataProvider.activePlans.length} Active System Packages Offering',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                              ),
                              const Text(
                                'Click manage options above to see assigned user counts or deploy package variations.',
                                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing),

              _sectionLabel('Attendance Verification Systems'),
              PrimaryButton(
                text: 'Launch Attendance QR Terminal Station',
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18, color: Colors.white),
                onPressed: () => _showQrAttendanceStation(context, dataProvider.selectedGymId),
              ),
              const SizedBox(height: AppTheme.spacing),

              // 🚀 UPDATED HEADER ROW: Added direct interactive routing shortcut forward onto AddStaffScreen
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _sectionLabel('Staff Management & Variable Permissions Matrix'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primary, size: 22),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddStaffScreen()),
                      );
                    },
                  )
                ],
              ),
              AppCard(
                child: Column(
                  children: [
                    dataProvider.activeStaff.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('No active staff registered on this branch node.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: dataProvider.activeStaff.length,
                            separatorBuilder: (_, __) => const Divider(color: AppTheme.border),
                            itemBuilder: (context, idx) {
                              final staff = dataProvider.activeStaff[idx];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(staff['name'] ?? 'Unnamed Employee', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                      Switch(
                                        value: staff['attendance_enabled'] ?? true,
                                        activeTrackColor: AppTheme.primary,
                                        onChanged: (val) => setState(() => staff['attendance_enabled'] = val),
                                      )
                                    ],
                                  ),
                                  Text('Role: ${staff['role'] ?? 'Trainer'}   •   Salary Base: ₹${staff['salary'] ?? '0'}/mo', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(icon: const Icon(Icons.edit_rounded, size: 14), onPressed: () {}),
                                      IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 14, color: AppTheme.danger), onPressed: () {}),
                                    ],
                                  )
                                ],
                              );
                            },
                          ),
                    const Divider(color: AppTheme.border, height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Active Staff Permissions Preview:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _permBadge('Manage Members', true),
                        _permBadge('Add/Del/Edit Plans', true),
                        _permBadge('Mark Attendance', true),
                        _permBadge('See Member Analytics', false),
                        _permBadge('See Expense Reports', false),
                        _permBadge('Download Reports', false),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing),

              _sectionLabel('Expense Ledger Controls Manager'),
              AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), side: const BorderSide(color: AppTheme.border)),
                        onPressed: () {},
                        child: const Text('+ Add Recurring Expense', style: TextStyle(fontSize: 11, color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), side: const BorderSide(color: AppTheme.border)),
                        onPressed: () {},
                        child: const Text('+ Add One-Time Expense', style: TextStyle(fontSize: 11, color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing),

              _sectionLabel('Automated Corporate Operations Systems'),
              _stubToggleCard('Invoice Generator Manager Panel', Icons.receipt_rounded),
              const SizedBox(height: 8),
              _stubToggleCard('Billing Address & Regulatory GST Manager', Icons.gavel_rounded),
              const SizedBox(height: 8),
              _stubToggleCard('Language Context Preferences', Icons.language_rounded),
              const SizedBox(height: 8),
              _stubToggleCard('Local Base Currency Preference (INR)', Icons.currency_rupee_rounded),
              const SizedBox(height: 8),
              _stubToggleCard('Help Desk Support Direct Portal Node', Icons.help_outline_rounded),
              const SizedBox(height: AppTheme.spacing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
    );
  }

  Widget _profileLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _permBadge(String label, bool enabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: enabled ? AppTheme.primary.withValues(alpha: 0.06) : AppTheme.border.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, color: enabled ? AppTheme.primary : AppTheme.textSecondary, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _stubToggleCard(String label, IconData icon) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary))),
          const Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.textSecondary),
        ],
      ),
    );
  }
}