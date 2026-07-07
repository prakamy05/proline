import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../../state/gym_data_provider.dart';

class AppRefreshWrapper extends StatelessWidget {
  final Widget child;

  const AppRefreshWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.primary,
      backgroundColor: AppTheme.cardBg,
      onRefresh: () async {
        // Enforces a single master database synchronization pipeline call universally
        final provider = Provider.of<GymDataProvider>(context, listen: false);
        await provider.reloadCurrentGymData();
      },
      // 🛡️ Safe-guard check: Ensures that nested list views inherit scroll behaviors 
      // even if the viewport layout content is shorter than the physical screen.
      child: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: true),
        child: child,
      ),
    );
  }
}