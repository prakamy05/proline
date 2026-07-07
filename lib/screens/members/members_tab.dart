import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_refresh_wrapper.dart';
import '../../state/gym_data_provider.dart';
import '../../models/member_model.dart';
import 'widgets/member_card.dart';
import 'add_member_screen.dart';

class MembersTab extends StatefulWidget {
  const MembersTab({super.key});

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> with AutomaticKeepAliveClientMixin {
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final dataProvider = Provider.of<GymDataProvider>(context);
    
    // 🚀 FIXED: Dynamic fallback initialization wrapper. If the provider doesn't have a 
    // global sorting flag initialized yet, we instantiate 'Expiry' as your default base vector.
    // This variable now survives pull-to-refresh teardowns permanently!
    final activeSortBy = dataProvider.memberSortCriteria ?? 'Expiry';
    
    // 🛡️ Step 1: Filter roster list according to active search queries
    List<Member> processedRoster = dataProvider.activeMembers.where((Member m) {
      final query = _searchQuery.toLowerCase();
      return m.name.toLowerCase().contains(query) ||
          m.phone.contains(query) ||
          (m.membershipNumber?.toLowerCase().contains(query) ?? false);
    }).toList();

    // 🚀 Step 2: Apply chosen sorting criteria from the provider state layer
    switch (activeSortBy) {
      case 'Latest Registered':
        processedRoster.sort((a, b) => b.id.compareTo(a.id));
        break;
        
      case 'Due Amount':
        processedRoster.sort((a, b) => b.dueAmount.compareTo(a.dueAmount));
        break;
        
      case 'Expiry':
        processedRoster.sort((a, b) {
          final dateA = dataProvider.getExpiryDateString(a.id);
          final dateB = dataProvider.getExpiryDateString(b.id);
          if (dateA == "N/A") return 1;
          if (dateB == "N/A") return -1;
          return dateA.compareTo(dateB);
        });
        break;
        
      case 'Plan Purchased':
        processedRoster.sort((a, b) => (a.membershipNumber ?? '').toLowerCase().compareTo((b.membershipNumber ?? '').toLowerCase()));
        break;
        
      case 'Member Updated':
      default:
        processedRoster.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          Container(
            color: AppTheme.cardBg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search by Name, Mobile, Membership ID...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
                    filled: true,
                    fillColor: AppTheme.background,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sort list profiles by:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    DropdownButton<String>(
                      value: activeSortBy,
                      underline: const SizedBox(),
                      style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600),
                      items: ['Expiry', 'Due Amount', 'Latest Registered', 'Member Updated', 'Plan Purchased']
                          .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          // 🚀 FIXED: Save choice value up directly to provider state tree.
                          // It updates UI triggers instantly and survives pull-to-refresh execution cycles safely!
                          dataProvider.updateMemberSortCriteria(val);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: AppRefreshWrapper(
              child: processedRoster.isEmpty
                  ? const Center(
                      child: SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: Text(
                          'No matching system records found.', 
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: processedRoster.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        return MemberCard(member: processedRoster[idx]);
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMemberScreen()));
        },
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}