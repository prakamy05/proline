import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../state/gym_data_provider.dart';
import 'package:proline/screens/auth/login_screen.dart';

// Operations View Screens
import 'package:proline/screens/gym/manage_branches_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final stateProvider = Provider.of<GymDataProvider>(context);

    return Drawer(
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(AppTheme.cardRadius),
          bottomRight: Radius.circular(AppTheme.cardRadius),
        ),
      ),
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppTheme.background,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ProLine SaaS',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                      ),
                      Text(
                        'Owner Terminal',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Gym Branch Switcher Row Expansion
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.business_rounded, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'SWITCH BRANCH',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          
          ...stateProvider.clientGyms.map((gym) {
            final bool isSelected = gym.id == stateProvider.selectedGymId;
            return ListTile(
              title: Text(
                gym.name,
                style: TextStyle(
                  fontSize: 13, 
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                ),
              ),
              trailing: isSelected ? const Icon(Icons.check_circle, size: 18, color: AppTheme.primary) : null,
              dense: true,
              onTap: () {
                stateProvider.changeBranch(gym.id);
                Navigator.pop(context);
              },
            );
          }),

          // 🚀 NEW: Dedicated Branch Administration Option Route Linkage Shortcut
          ListTile(
            leading: const Icon(Icons.hub_outlined, size: 20, color: AppTheme.primary),
            title: const Text(
              'Manage Branches Matrix', 
              style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.bold)
            ),
            dense: true,
            onTap: () {
              Navigator.pop(context); // Clear top contextual active menu layer block safely
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageBranchesScreen()),
              );
            },
          ),

          const Divider(color: AppTheme.border, height: 24),
          
          ListTile(
            leading: const Icon(Icons.receipt_long_rounded, size: 20, color: AppTheme.textPrimary),
            title: const Text('Expenses Ledger', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Global Expense management sub-view shortcut triggered.')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.system_update_alt_rounded, size: 20, color: AppTheme.textPrimary),
            title: const Text('Check For Updates', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('System is live on v1.0.0 (Latest Release Version).')),
              );
            },
          ),
          const Spacer(),
          const Divider(color: AppTheme.border, height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, size: 20, color: AppTheme.danger),
            title: const Text('Logout Workspace', style: TextStyle(color: AppTheme.danger, fontSize: 13, fontWeight: FontWeight.w600)),
            onTap: () async {
              // Clear secure hardware persistent tokens
              await stateProvider.clearActiveWorkspaceSession();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(height: AppTheme.padding),
        ],
      ),
    );
  }
}