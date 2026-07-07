import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../models/member_model.dart';
import '../../../../state/gym_data_provider.dart';
import '../member_details_screen.dart';

class MemberCard extends StatelessWidget {
  final Member member;

  const MemberCard({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<GymDataProvider>(context, listen: true);
    final String expiryStr = dataProvider.getExpiryDateString(member.id);
    
    // Evaluate Date and Check-in Boundaries at runtime
    final DateTime? expiryDate = expiryStr != 'N/A' ? DateTime.tryParse(expiryStr) : null;
    final bool isExpired = expiryDate != null && expiryDate.isBefore(DateTime.now());
    final bool isBlocked = member.status == 'BLOCKED';
    
    final bool isAlreadyCheckedIn = dataProvider.isMemberCheckedInToday(member.id);
    final bool canMarkAttendance = !isBlocked && !isExpired && !isAlreadyCheckedIn;

    // 🚀 FIXED: Evaluate if it's custom by reading the membership plan details tracking attribute
    final isCustomPlan = (member.membershipNumber == null || 
                          member.membershipNumber!.isEmpty || 
                          member.membershipNumber!.toLowerCase() == 'custom' ||
                          !dataProvider.activePlans.any((p) => p.name.toLowerCase() == member.membershipNumber!.toLowerCase()));
    final displayPlanName = isCustomPlan ? "Custom" : member.membershipNumber!;

    return Opacity(
      opacity: isBlocked ? 0.55 : 1.0,
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MemberDetailsScreen(member: member, expiryStr: expiryStr)),
                );
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
                    child: Text(
                      member.name[0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              member.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                            ),
                            if (isBlocked) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                child: const Text('BLOCKED', style: TextStyle(color: AppTheme.danger, fontSize: 8, fontWeight: FontWeight.bold)),
                              ),
                            ],
                            if (isExpired && !isBlocked) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                child: const Text('EXPIRED', style: TextStyle(color: AppTheme.warning, fontSize: 8, fontWeight: FontWeight.bold)),
                              ),
                            ],
                            if (isAlreadyCheckedIn && !isBlocked && !isExpired) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                child: const Text('PRESENT', style: TextStyle(color: AppTheme.success, fontSize: 8, fontWeight: FontWeight.bold)),
                              ),
                            ]
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(member.phone, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        const SizedBox(height: 4),
                        // Renders Custom status vs native catalog text flags layout properties
                        Row(
                          children: [
                            Text(
                              '$displayPlanName  •  ', 
                              style: TextStyle(
                                fontSize: 11, 
                                fontWeight: FontWeight.w600, 
                                color: isCustomPlan ? AppTheme.warning : AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              'Plan Expiry: $expiryStr',
                              style: TextStyle(
                                fontSize: 11, 
                                color: isExpired ? AppTheme.danger : AppTheme.textPrimary, 
                                fontWeight: FontWeight.w500
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Due Amount', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                      Text(
                        '₹${member.dueAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: member.dueAmount > 0 ? AppTheme.danger : AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.border, height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.call_rounded, size: 18, color: AppTheme.primary),
                  onPressed: () {},
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppTheme.success),
                  onPressed: () {},
                ),
                Flexible(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () async {
                      if (!canMarkAttendance) {
                        String warningMessage = 'Action unavailable.';
                        if (isBlocked) {
                          warningMessage = 'Attendance Denied: This member account is administrative-blocked.';
                        } else if (isExpired) {
                          warningMessage = 'Attendance Denied: Membership tier has expired.';
                        } else if (isAlreadyCheckedIn) {
                          warningMessage = 'Attendance has already been marked for this member today.';
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(warningMessage),
                            backgroundColor: isAlreadyCheckedIn ? AppTheme.textSecondary : AppTheme.danger,
                          ),
                        );
                        return;
                      }

                      final provider = Provider.of<GymDataProvider>(context, listen: false);
                      bool trackingSuccess = await provider.markAttendance(member.id);

                      if (context.mounted) {
                        if (trackingSuccess) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Attendance securely registered for ${member.name}'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Network error: Failed to log check-in entry.'),
                              backgroundColor: AppTheme.danger,
                            ),
                          );
                        }
                      }
                    },
                    icon: Icon(
                      isAlreadyCheckedIn ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded, 
                      size: 16, 
                      color: canMarkAttendance 
                          ? AppTheme.primary 
                          : (isAlreadyCheckedIn ? AppTheme.success : AppTheme.textSecondary)
                    ),
                    label: Text(
                      isAlreadyCheckedIn ? 'Marked' : 'Attendance', 
                      style: TextStyle(
                        fontSize: 11,
                        color: canMarkAttendance 
                            ? AppTheme.primary 
                            : (isAlreadyCheckedIn ? AppTheme.success : AppTheme.textSecondary),
                        fontWeight: isAlreadyCheckedIn ? FontWeight.bold : FontWeight.normal
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Flexible(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {},
                    child: const Text(
                      'Renew Plan', 
                      style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(isBlocked ? Icons.lock_open_rounded : Icons.block_rounded, size: 18, color: AppTheme.danger),
                  onPressed: () {},
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}