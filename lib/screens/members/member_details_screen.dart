import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../models/member_model.dart';
import '../../state/gym_data_provider.dart';

class MemberDetailsScreen extends StatelessWidget {
  final Member member;
  final String expiryStr;

  const MemberDetailsScreen({super.key, required this.member, required this.expiryStr});

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<GymDataProvider>(context, listen: false);
    
    // 🚀 FIXED: Update parsing parameters to link custom labels to plan details text strings
    final isCustomPlan = (member.membershipNumber == null || 
                          member.membershipNumber!.isEmpty || 
                          member.membershipNumber!.toLowerCase() == 'custom' ||
                          !dataProvider.activePlans.any((p) => p.name.toLowerCase() == member.membershipNumber!.toLowerCase()));
    final displayPlanName = isCustomPlan ? "Custom" : member.membershipNumber!;

    // Parse true relational data timeline configurations
    final String formattedJoiningDate = member.joinedDate.toIso8601String().substring(0, 10);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Roster Ledger File', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        leading: const BackButton(color: AppTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
                    child: Text(
                      member.name[0].toUpperCase(), 
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(member.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        Text('System Reference ID: ${member.id}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        Text('Joined: $formattedJoiningDate', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Profile Parameters', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                children: [
                  _metaField('Primary Phone Number', member.phone),
                  _metaField('Electronic Mail', member.email ?? 'N/A'),
                  // THE FIXED LINE:
                  _metaField('Biological Sex Vector', member.gender ?? 'Unspecified'),
                  _metaField('Address Field Location', member.address ?? 'No address registered'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Active Plan Matrix Timeline', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            AppCard(
              color: isCustomPlan ? AppTheme.warning.withValues(alpha: 0.02) : AppTheme.primary.withValues(alpha: 0.02),
              border: BorderSide(color: isCustomPlan ? AppTheme.warning : AppTheme.primary, width: 1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    displayPlanName, 
                    style: TextStyle(
                      fontSize: 13, 
                      fontWeight: FontWeight.w600, 
                      color: isCustomPlan ? AppTheme.warning : AppTheme.primary,
                    ),
                  ),
                  Text('Expires: $expiryStr', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Historical Ledger Purchase Registry', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            AppCard(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 1,
                separatorBuilder: (_, __) => const Divider(color: AppTheme.border),
                itemBuilder: (context, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayPlanName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text('Purchased on $formattedJoiningDate', style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                        ],
                      ),
                      Text(
                        isCustomPlan ? 'Custom Rate' : '₹${member.dueAmount > 0 ? "Calculated" : "Paid"}', 
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text('Attendance Metrics Log', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            const AppCard(
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('2026-06-18 07:15 AM', style: TextStyle(fontSize: 12)), Text('Checked In', style: TextStyle(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.bold))]),
                  Divider(color: AppTheme.border),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('2026-06-17 08:30 AM', style: TextStyle(fontSize: 12)), Text('Checked In', style: TextStyle(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.bold))]),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _metaField(String heading, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(heading, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}