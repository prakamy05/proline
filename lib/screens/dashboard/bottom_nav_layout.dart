import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../navigation/app_drawer.dart';
import '../../state/gym_data_provider.dart';
import '../members/members_tab.dart';
import '../trends/trends_tab.dart';
import '../finance/finance_tab.dart';
import '../gym/gym_management_tab.dart';

class BottomNavLayout extends StatefulWidget {
  const BottomNavLayout({super.key});

  @override
  State<BottomNavLayout> createState() => _BottomNavLayoutState();
}

class _BottomNavLayoutState extends State<BottomNavLayout> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _tabNames = [
    'Members',
    'Trends',
    'Finance Overview',
    'Gym Management',
  ];

  final List<Widget> _views = [
    const MembersTab(),
    const TrendsTab(),
    const FinanceTab(),
    const GymManagementTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Safely triggers a layout sync update if needed on launch
      Provider.of<GymDataProvider>(context, listen: false).reloadCurrentGymData();
    });
  }
  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<GymDataProvider>(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppTheme.textPrimary, size: 22),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          _tabNames[_currentIndex],
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
        elevation: 0,
        backgroundColor: AppTheme.cardBg,
        shape: const Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      body: dataProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : IndexedStack(index: _currentIndex, children: _views),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: AppTheme.primary.withValues(alpha: 0.08),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary);
            }
            return const TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: AppTheme.textSecondary);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppTheme.primary, size: 22);
            }
            return const IconThemeData(color: AppTheme.textSecondary, size: 22);
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (int idx) => setState(() => _currentIndex = idx),
          backgroundColor: AppTheme.cardBg,
          elevation: 10,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.people_outline_rounded), selectedIcon: Icon(Icons.people_rounded), label: 'Members'),
            NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics_rounded), label: 'Trends'),
            NavigationDestination(icon: Icon(Icons.monetization_on_outlined), selectedIcon: Icon(Icons.monetization_on_rounded), label: 'Finance'),
            NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center_rounded), label: 'Gym'),
          ],
        ),
      ),
    );
  }
}