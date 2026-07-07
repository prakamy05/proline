import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; 
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/stat_card.dart';
import '../../state/gym_data_provider.dart';

class TrendsTab extends StatefulWidget {
  const TrendsTab({super.key});

  @override
  State<TrendsTab> createState() => _TrendsTabState();
}

class _TrendsTabState extends State<TrendsTab> with AutomaticKeepAliveClientMixin {
  String _timeRange = 'Weekly';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final dataProvider = Provider.of<GymDataProvider>(context);
    final DateTime now = DateTime.now();
    final String todayStr = now.toIso8601String().substring(0, 10);

    // ==========================================
    // 📊 CORE LEDGER CALCULATIONS
    // ==========================================
    final int totalRoster = dataProvider.activeMembers.length;
    final int blockedCount = dataProvider.activeMembers.where((m) => m.status == 'BLOCKED').length;

    final int todayAttendanceCount = dataProvider.rawAttendance.where((log) {
      final dateStr = log['attendance_date']?.toString().substring(0, 10) ?? '';
      return dateStr == todayStr;
    }).length;

    int expToday = 0;
    int exp3Days = 0;
    int exp7Days = 0;
    int exp12Days = 0;
    int totalExpiredCount = 0;

    for (var m in dataProvider.activeMembers) {
      final expStr = dataProvider.getExpiryDateString(m.id);
      if (expStr == 'N/A') continue;
      
      final DateTime? expiryDate = DateTime.tryParse(expStr);
      if (expiryDate == null) continue;

      if (expiryDate.isBefore(now)) {
        totalExpiredCount++;
        if (expStr == todayStr) expToday++;
      } else {
        final int daysUntilExpiry = expiryDate.difference(now).inDays;
        if (daysUntilExpiry <= 3) exp3Days++;
        if (daysUntilExpiry <= 7) exp7Days++;
        if (daysUntilExpiry <= 12) exp12Days++;
      }
    }

    int joinsToday = 0;
    int joinsThisWeek = 0;
    int joinsThisMonth = 0;

    for (var m in dataProvider.activeMembers) {
      final DateTime? jDate = DateTime.tryParse(m.joinedDate.toString());
      if (jDate == null) continue;
      final int deltaDays = now.difference(jDate).inDays;
      if (deltaDays == 0) joinsToday++;
      if (deltaDays <= 7) joinsThisWeek++;
      if (deltaDays <= 30) joinsThisMonth++;
    }

    // ==========================================
    // 📈 DYNAMIC TRENDS TIME WINDOW CONTROLLER
    // ==========================================
    List<String> chartLabels = [];
    List<double> chartCapacity = [];
    List<double> chartVelocity = [];
    List<double> chartAttendance = [];

    switch (_timeRange) {
      case 'Daily':
        for (int i = 4; i >= 0; i--) {
          final targetDay = now.subtract(Duration(days: i));
          chartLabels.add(DateFormat('E').format(targetDay));
          
          double capacityCount = 0;
          double velocityCount = 0;
          double attendanceCount = 0;

          for (var m in dataProvider.activeMembers) {
            final DateTime? jDate = DateTime.tryParse(m.joinedDate.toString());
            if (jDate != null) {
              if (jDate.isBefore(targetDay) || _isSameDay(jDate, targetDay)) capacityCount++;
              if (_isSameDay(jDate, targetDay)) velocityCount++;
            }
          }
          for (var log in dataProvider.rawAttendance) {
            final DateTime? aDate = DateTime.tryParse(log['attendance_date']?.toString() ?? '');
            if (aDate != null && _isSameDay(aDate, targetDay)) attendanceCount++;
          }
          chartCapacity.add(capacityCount);
          chartVelocity.add(velocityCount);
          chartAttendance.add(attendanceCount);
        }
        break;

      case 'Monthly':
        final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        for (int i = 4; i >= 0; i--) {
          final date = DateTime(now.year, now.month - i, 1);
          chartLabels.add(monthNames[date.month - 1]);

          double capacityCount = 0;
          double velocityCount = 0;
          double attendanceCount = 0;

          for (var m in dataProvider.activeMembers) {
            final DateTime? jDate = DateTime.tryParse(m.joinedDate.toString());
            if (jDate != null) {
              if (jDate.year < date.year || (jDate.year == date.year && jDate.month <= date.month)) capacityCount++;
              if (jDate.year == date.year && jDate.month == date.month) velocityCount++;
            }
          }
          for (var log in dataProvider.rawAttendance) {
            final DateTime? aDate = DateTime.tryParse(log['attendance_date']?.toString() ?? '');
            if (aDate != null && aDate.year == date.year && aDate.month == date.month) attendanceCount++;
          }
          chartCapacity.add(capacityCount);
          chartVelocity.add(velocityCount);
          chartAttendance.add(attendanceCount);
        }
        break;

      case 'Weekly':
      default:
        for (int i = 4; i >= 0; i--) {
          final targetWeekStart = now.subtract(Duration(days: i * 7));
          chartLabels.add('W${5 - i}');

          double capacityCount = 0;
          double velocityCount = 0;
          double attendanceCount = 0;

          for (var m in dataProvider.activeMembers) {
            final DateTime? jDate = DateTime.tryParse(m.joinedDate.toString());
            if (jDate != null) {
              if (jDate.isBefore(targetWeekStart.add(const Duration(days: 7)))) capacityCount++;
              if (jDate.isAfter(targetWeekStart) && jDate.isBefore(targetWeekStart.add(const Duration(days: 7)))) velocityCount++;
            }
          }
          for (var log in dataProvider.rawAttendance) {
            final DateTime? aDate = DateTime.tryParse(log['attendance_date']?.toString() ?? '');
            if (aDate != null && aDate.isAfter(targetWeekStart) && aDate.isBefore(targetWeekStart.add(const Duration(days: 7)))) attendanceCount++;
          }
          chartCapacity.add(capacityCount);
          chartVelocity.add(velocityCount);
          chartAttendance.add(attendanceCount);
        }
        break;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Performance Indicators', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.cardBg,
        elevation: 0.5,
        actions: [
          Theme(
            data: Theme.of(context).copyWith(canvasColor: AppTheme.cardBg),
            child: DropdownButton<String>(
              value: _timeRange,
              underline: const SizedBox(),
              style: const TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.bold),
              items: ['Daily', 'Weekly', 'Monthly']
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _timeRange = val);
              },
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChartSection('Active System Capacity Trends (Total)', chartLabels, chartCapacity, AppTheme.primary),
            const SizedBox(height: 20),
            _buildChartSection('New Members Joined (Velocity)', chartLabels, chartVelocity, AppTheme.success),
            const SizedBox(height: 20),
            _buildChartSection('Attendance Marked Profiles Density', chartLabels, chartAttendance, AppTheme.warning),
            const SizedBox(height: 28),

            const Text('Data Summary Ledger', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),

            AppCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    _summaryRow("Today's Total Marked Attendances", "$todayAttendanceCount Checked In"),
                    _summaryRow("Expiries Realized Today", "$expToday Accounts"),
                    _summaryRow("Upcoming Expiries (3 days)", "$exp3Days Accounts"),
                    _summaryRow("Upcoming Expiries (7 days)", "$exp7Days Accounts"),
                    _summaryRow("Upcoming Expiries (12 days)", "$exp12Days Accounts"),
                    _summaryRow("Unique Active Members Matrix", "$totalRoster Profiles"),
                    _summaryRow("New Members: Today", "$joinsToday Registered"),
                    _summaryRow("New Members: This Week", "$joinsThisWeek Registered"),
                    _summaryRow("New Members: This Month", "$joinsThisMonth Registered"),
                    _summaryRow("Blocked/Frozen Members Accounts", "$blockedCount Accounts"),
                    _summaryRow("Expired Members Balance", "$totalExpiredCount Accounts"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildChartSection(String title, List<String> labels, List<double> values, Color barColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        AppCard(
          child: Container(
            height: 160, 
            padding: const EdgeInsets.only(top: 16, right: 8, bottom: 8, left: 4),
            child: TrendAxisChartWidget(labels: labels, values: values, barColor: barColor),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

// ==========================================
// 📊 CUSTOM AXIS TREND RENDERING WIDGET
// ==========================================
class TrendAxisChartWidget extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final Color barColor;

  const TrendAxisChartWidget({
    super.key,
    required this.labels,
    required this.values,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    double maxTargetValue = values.isEmpty ? 10.0 : values.fold(10.0, (max, v) => v > max ? v : max);
    if (maxTargetValue <= 0) maxTargetValue = 10.0;
    
    maxTargetValue = maxTargetValue < 10 ? maxTargetValue.ceilToDouble() : ((maxTargetValue / 5).ceil() * 5).toDouble();
    final List<double> yTicks = [maxTargetValue, maxTargetValue * 0.5, 0.0];

    return Row(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: yTicks.map((tick) => SizedBox(
            width: 30,
            child: Text(
              tick.toStringAsFixed(0),
              style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          )).toList(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(values.length, (index) {
                    final double currentRawValue = values[index];
                    final double calculatedHeightFactor = maxTargetValue > 0 ? (currentRawValue / maxTargetValue) : 0.0;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (currentRawValue > 0)
                                  Text(
                                    currentRawValue.toStringAsFixed(0),
                                    style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                  ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: (constraints.maxHeight - 16) * calculatedHeightFactor.clamp(0.01, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: barColor.withOpacity(0.85),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(4),
                                        topRight: Radius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const Divider(height: 12, thickness: 1, color: AppTheme.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: labels.map((label) => Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}