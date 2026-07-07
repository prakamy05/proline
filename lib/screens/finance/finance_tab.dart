import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; 
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/stat_card.dart';
import '../../state/gym_data_provider.dart';
import '../../models/plan_model.dart'; 

class FinanceTab extends StatefulWidget {
  const FinanceTab({super.key});

  @override
  State<FinanceTab> createState() => _FinanceTabState();
}

class _FinanceTabState extends State<FinanceTab> with AutomaticKeepAliveClientMixin {
  // Top Overview Window Filter Option state selector
  String _overviewFilter = 'Last 30 Days';

  // Individual chart time range filter selectors (Empty default prints downward arrow only)
  String _revenueChartFilter = '';
  String _expensesChartFilter = '';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final dataProvider = Provider.of<GymDataProvider>(context);
    final DateTime now = DateTime.now();

    // Safe null guards for arrays during hot updates
    final List<dynamic> membersList = dataProvider.activeMembers ?? [];
    final List<dynamic> expensesList = dataProvider.rawExpenses ?? [];
    final List<dynamic> staffList = dataProvider.activeStaff ?? [];

    if (dataProvider.isLoading && membersList.isEmpty) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    // ==========================================
    // 📊 1. METRICS OVERVIEW DATA RESOLUTION LAYER
    // ==========================================
    DateTime limitDate;
    int sparklinePointsCount = 7;
    
    switch (_overviewFilter) {
      case 'Today':
        limitDate = DateTime(now.year, now.month, now.day);
        sparklinePointsCount = 6;
        break;
      case 'Last 7 Days':
        limitDate = now.subtract(const Duration(days: 7));
        sparklinePointsCount = 7;
        break;
      case 'Last 6 Months':
        limitDate = DateTime(now.year, now.month - 6, now.day);
        sparklinePointsCount = 6;
        break;
      case 'Last 1 Year':
        limitDate = DateTime(now.year - 1, now.month, now.day);
        sparklinePointsCount = 12;
        break;
      case 'Last 30 Days':
      default:
        limitDate = now.subtract(const Duration(days: 30));
        sparklinePointsCount = 4; // 4 weeks
        break;
    }

    double totalPlanVolumeOverview = 0.0;
    double duesOverview = 0.0;

    for (var member in membersList) {
      final DateTime? joinedDate = DateTime.tryParse(member.joinedDate.toString());
      if (joinedDate == null) continue;

      if (_overviewFilter == 'Today' ? _isSameDay(joinedDate, now) : joinedDate.isAfter(limitDate)) {
        duesOverview += (double.tryParse(member.dueAmount.toString()) ?? 0.0);
        
        final planMatch = (dataProvider.activePlans ?? []).firstWhere(
          (p) => p.name.toLowerCase() == (member.membershipNumber ?? '').toLowerCase(),
          orElse: () => const Plan(id: -1, gymId: 0, name: '', price: 0, durationValue: 30, durationType: 'DAYS'),
        );
        
        if (planMatch.id != -1) {
          totalPlanVolumeOverview += planMatch.price;
        } else {
          totalPlanVolumeOverview += ((double.tryParse(member.dueAmount.toString()) ?? 0.0) > 0 
              ? (double.tryParse(member.dueAmount.toString()) ?? 0.0) 
              : 1500.0);
        }
      }
    }

    final double revenueOverview = totalPlanVolumeOverview - duesOverview;

    double expensesOverview = 0.0;
    for (var exp in expensesList) {
      final date = DateTime.tryParse(exp['expense_date'].toString());
      if (date != null && (_overviewFilter == 'Today' ? _isSameDay(date, now) : date.isAfter(limitDate))) {
        expensesOverview += double.tryParse(exp['amount'].toString()) ?? 0.0;
      }
    }
    
    double staffSalaryFactor = 1.0;
    if (_overviewFilter == 'Today') staffSalaryFactor = 1 / 30;
    if (_overviewFilter == 'Last 7 Days') staffSalaryFactor = 7 / 30;
    if (_overviewFilter == 'Last 6 Months') staffSalaryFactor = 6;
    if (_overviewFilter == 'Last 1 Year') staffSalaryFactor = 12;

    for (var staff in staffList) {
      if (staff['is_active'] == true) {
        expensesOverview += ((double.tryParse(staff['salary'].toString()) ?? 0.0) / 12) * staffSalaryFactor;
      }
    }

    // Generate accurate historical trend spark arrays matching current timeline filter
    List<double> sparkRevenue = _generateSparklineData(dataProvider, _overviewFilter, 'revenue', now, sparklinePointsCount);
    List<double> sparkDues = _generateSparklineData(dataProvider, _overviewFilter, 'dues', now, sparklinePointsCount);
    List<double> sparkExpenses = _generateSparklineData(dataProvider, _overviewFilter, 'expenses', now, sparklinePointsCount);

    // ==========================================
    // 📈 2. INDEPENDENT TIMELINE AGGREGATIONS
    // ==========================================
    final String revFilter = _revenueChartFilter.isEmpty ? 'Monthly' : _revenueChartFilter;
    final String expFilter = _expensesChartFilter.isEmpty ? 'Monthly' : _expensesChartFilter;

    final revenueChartData = _buildTimelineData(dataProvider, revFilter, 'revenue', now);
    final expensesChartData = _buildTimelineData(dataProvider, expFilter, 'expenses', now);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Finance Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.cardBg,
        elevation: 0.5,
        actions: [
          Theme(
            data: Theme.of(context).copyWith(canvasColor: AppTheme.cardBg),
            child: DropdownButton<String>(
              value: _overviewFilter,
              underline: const SizedBox(),
              style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold),
              items: ['Today', 'Last 7 Days', 'Last 30 Days', 'Last 6 Months', 'Last 1 Year']
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _overviewFilter = val);
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
            // 🚀 FIXED: Rendered overview rows on independent individual rows with dynamic spark graph vectors
            Stack(
              children: [
                StatCard(
                  title: 'Revenue Collected Overview',
                  value: '₹${revenueOverview.toStringAsFixed(0)}',
                  subtext: _overviewFilter,
                  valueColor: AppTheme.success,
                ),
                Positioned(
                  right: 16,
                  bottom: 14,
                  width: 90,
                  height: 32,
                  child: CustomPaint(painter: SparklineMiniPainter(color: Colors.green, values: sparkRevenue)),
                )
              ],
            ),
            const SizedBox(height: 12),
            Stack(
              children: [
                StatCard(
                  title: 'Due Amounts Overview',
                  value: '₹${duesOverview.toStringAsFixed(0)}',
                  subtext: _overviewFilter,
                  valueColor: AppTheme.warning,
                ),
                Positioned(
                  right: 16,
                  bottom: 14,
                  width: 90,
                  height: 32,
                  child: CustomPaint(painter: SparklineMiniPainter(color: Colors.amber, values: sparkDues)),
                )
              ],
            ),
            const SizedBox(height: 12),
            Stack(
              children: [
                StatCard(
                  title: 'Expenses Overview',
                  value: '₹${expensesOverview.toStringAsFixed(0)}',
                  subtext: _overviewFilter,
                  valueColor: AppTheme.danger,
                ),
                Positioned(
                  right: 16,
                  bottom: 14,
                  width: 90,
                  height: 32,
                  child: CustomPaint(painter: SparklineMiniPainter(color: Colors.red, values: sparkExpenses)),
                )
              ],
            ),
            const SizedBox(height: 28),

            // 💸 1. REVENUE COLLECTED CHART CARD
            _buildChartSection(
              title: 'Revenue Collected',
              filterValue: _revenueChartFilter,
              labels: revenueChartData.labels,
              values: revenueChartData.values,
              barColor: AppTheme.success,
              onFilterChanged: (val) => setState(() => _revenueChartFilter = val ?? ''),
            ),
            const SizedBox(height: 20),

            // 📉 2. EXPENSES CHART CARD
            _buildChartSection(
              title: 'Expenses',
              filterValue: _expensesChartFilter,
              labels: expensesChartData.labels,
              values: expensesChartData.values,
              barColor: AppTheme.warning,
              onFilterChanged: (val) => setState(() => _expensesChartFilter = val ?? ''),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildChartSection({
    required String title,
    required String filterValue,
    required List<String> labels,
    required List<double> values,
    required Color barColor,
    required ValueChanged<String?> onFilterChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            Theme(
              data: Theme.of(context).copyWith(canvasColor: AppTheme.cardBg),
              child: DropdownButton<String>(
                value: filterValue.isEmpty ? null : filterValue,
                hint: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primary, size: 20),
                underline: const SizedBox(),
                style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold),
                items: ['Daily', 'Weekly', 'Monthly', 'Yearly'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: onFilterChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AppCard(
          child: Container(
            height: 180,
            padding: const EdgeInsets.only(top: 16, right: 8, bottom: 8, left: 4),
            child: SimpleAxisChartWidget(labels: labels, values: values, barColor: barColor),
          ),
        ),
      ],
    );
  }

  // 🚀 FIXED: Dynamic lookup tool to generate accurate points for Sparkline vectors
  List<double> _generateSparklineData(GymDataProvider provider, String filter, String type, DateTime now, int points) {
    List<double> rawPoints = [];
    for (int i = points - 1; i >= 0; i--) {
      DateTime targetDate;
      if (filter == 'Last 6 Months' || filter == 'Last 1 Year') {
        targetDate = DateTime(now.year, now.month - i, 1);
        rawPoints.add(_computeValueForMonth(provider, targetDate.year, targetDate.month, type));
      } else if (filter == 'Last 30 Days') {
        targetDate = now.subtract(Duration(days: i * 7));
        rawPoints.add(_computeValueForRange(provider, targetDate.subtract(const Duration(days: 7)), targetDate, type));
      } else {
        targetDate = now.subtract(Duration(days: i));
        rawPoints.add(_computeValueForDay(provider, targetDate, type));
      }
    }
    double highVal = rawPoints.fold(1.0, (m, v) => v > m ? v : m);
    return rawPoints.map((v) => v / highVal).toList();
  }

  _TimelinePayload _buildTimelineData(GymDataProvider provider, String filter, String type, DateTime now) {
    List<String> labels = [];
    List<double> values = [];

    if (filter == 'Daily') {
      for (int i = 11; i >= 0; i--) {
        final targetDay = now.subtract(Duration(days: i));
        labels.add(DateFormat('dd/MM').format(targetDay));
        values.add(_computeValueForDay(provider, targetDay, type));
      }
    } else if (filter == 'Weekly') {
      for (int i = 7; i >= 0; i--) {
        final targetWeekStart = now.subtract(Duration(days: i * 7));
        labels.add('Wk -${i}');
        values.add(_computeValueForRange(provider, targetWeekStart, targetWeekStart.add(const Duration(days: 7)), type));
      }
    } else if (filter == 'Yearly') {
      for (int i = 3; i >= 0; i--) {
        final int targetYear = now.year - i;
        labels.add(targetYear.toString());
        values.add(_computeValueForYear(provider, targetYear, type));
      }
    } else {
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      for (int i = 7; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i, 1);
        labels.add(monthNames[date.month - 1]);
        values.add(_computeValueForMonth(provider, date.year, date.month, type));
      }
    }

    return _TimelinePayload(labels, values);
  }

  double _computeValueForDay(GymDataProvider provider, DateTime target, String type) {
    double sum = 0.0;
    final list = provider.activeMembers ?? [];
    if (type == 'revenue' || type == 'dues') {
      for (var m in list) {
        final d = DateTime.tryParse(m.joinedDate.toString());
        if (d != null && _isSameDay(d, target)) {
          final curDue = double.tryParse(m.dueAmount.toString()) ?? 0.0;
          if (type == 'dues') sum += curDue;
          if (type == 'revenue') {
            final pMatch = (provider.activePlans ?? []).firstWhere((p) => p.name.toLowerCase() == (m.membershipNumber ?? '').toLowerCase(), orElse: () => const Plan(id: -1, gymId: 0, name: '', price: 0, durationValue: 30, durationType: 'DAYS'));
            sum += (pMatch.id != -1 ? pMatch.price : 1500.0) - curDue;
          }
        }
      }
    } else {
      for (var e in (provider.rawExpenses ?? [])) {
        final d = DateTime.tryParse(e['expense_date'].toString());
        if (d != null && _isSameDay(d, target)) sum += double.tryParse(e['amount'].toString()) ?? 0.0;
      }
    }
    return sum < 0 ? 0 : sum;
  }

  double _computeValueForRange(GymDataProvider provider, DateTime start, DateTime end, String type) {
    double sum = 0.0;
    final list = provider.activeMembers ?? [];
    if (type == 'revenue' || type == 'dues') {
      for (var m in list) {
        final d = DateTime.tryParse(m.joinedDate.toString());
        if (d != null && d.isAfter(start) && d.isBefore(end)) {
          final curDue = double.tryParse(m.dueAmount.toString()) ?? 0.0;
          if (type == 'dues') sum += curDue;
          if (type == 'revenue') {
            final pMatch = (provider.activePlans ?? []).firstWhere((p) => p.name.toLowerCase() == (m.membershipNumber ?? '').toLowerCase(), orElse: () => const Plan(id: -1, gymId: 0, name: '', price: 0, durationValue: 30, durationType: 'DAYS'));
            sum += (pMatch.id != -1 ? pMatch.price : 1500.0) - curDue;
          }
        }
      }
    } else {
      for (var e in (provider.rawExpenses ?? [])) {
        final d = DateTime.tryParse(e['expense_date'].toString());
        if (d != null && d.isAfter(start) && d.isBefore(end)) sum += double.tryParse(e['amount'].toString()) ?? 0.0;
      }
    }
    return sum < 0 ? 0 : sum;
  }

  double _computeValueForMonth(GymDataProvider provider, int year, int month, String type) {
    double sum = 0.0;
    final list = provider.activeMembers ?? [];
    if (type == 'revenue' || type == 'dues') {
      for (var m in list) {
        final d = DateTime.tryParse(m.joinedDate.toString());
        if (d != null && d.year == year && d.month == month) {
          final curDue = double.tryParse(m.dueAmount.toString()) ?? 0.0;
          if (type == 'dues') sum += curDue;
          if (type == 'revenue') {
            final pMatch = (provider.activePlans ?? []).firstWhere((p) => p.name.toLowerCase() == (m.membershipNumber ?? '').toLowerCase(), orElse: () => const Plan(id: -1, gymId: 0, name: '', price: 0, durationValue: 30, durationType: 'DAYS'));
            sum += (pMatch.id != -1 ? pMatch.price : 1500.0) - curDue;
          }
        }
      }
    } else {
      for (var e in (provider.rawExpenses ?? [])) {
        final d = DateTime.tryParse(e['expense_date'].toString());
        if (d != null && d.year == year && d.month == month) sum += double.tryParse(e['amount'].toString()) ?? 0.0;
      }
    }
    return sum < 0 ? 0 : sum;
  }

  double _computeValueForYear(GymDataProvider provider, int year, String type) {
    double sum = 0.0;
    final list = provider.activeMembers ?? [];
    if (type == 'revenue' || type == 'dues') {
      for (var m in list) {
        final d = DateTime.tryParse(m.joinedDate.toString());
        if (d != null && d.year == year) {
          final curDue = double.tryParse(m.dueAmount.toString()) ?? 0.0;
          if (type == 'dues') sum += curDue;
          if (type == 'revenue') {
            final pMatch = (provider.activePlans ?? []).firstWhere((p) => p.name.toLowerCase() == (m.membershipNumber ?? '').toLowerCase(), orElse: () => const Plan(id: -1, gymId: 0, name: '', price: 0, durationValue: 30, durationType: 'DAYS'));
            sum += (pMatch.id != -1 ? pMatch.price : 1500.0) - curDue;
          }
        }
      }
    } else {
      for (var e in (provider.rawExpenses ?? [])) {
        final d = DateTime.tryParse(e['expense_date'].toString());
        if (d != null && d.year == year) sum += double.tryParse(e['amount'].toString()) ?? 0.0;
      }
    }
    return sum < 0 ? 0 : sum;
  }
}

class _TimelinePayload {
  final List<String> labels;
  final List<double> values;
  _TimelinePayload(this.labels, this.values);
}

class SimpleAxisChartWidget extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final Color barColor;

  const SimpleAxisChartWidget({
    super.key,
    required this.labels,
    required this.values,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final List<double> safeValues = values ?? [];
    double maxTargetValue = safeValues.isEmpty ? 100.0 : safeValues.fold(100.0, (max, v) => v > max ? v : max);
    if (maxTargetValue <= 0) maxTargetValue = 100.0;
    
    if (maxTargetValue > 1000) {
      maxTargetValue = ((maxTargetValue / 1000).ceil() * 1000).toDouble();
    } else {
      maxTargetValue = ((maxTargetValue / 100).ceil() * 100).toDouble();
    }

    final List<double> yTicks = [maxTargetValue, maxTargetValue * 0.66, maxTargetValue * 0.33, 0.0];

    return Row(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: yTicks.map((tick) => SizedBox(
            width: 52,
            child: Text(
              '₹${tick.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          )).toList(),
        ),
        const SizedBox(width: 8),
        
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true, 
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: ((labels ?? []).length * 60.0).clamp(MediaQuery.of(context).size.width - 90, 1000.0),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(safeValues.length, (index) {
                        final double currentRawValue = safeValues[index];
                        final double calculatedHeightFactor = currentRawValue / maxTargetValue;

                        return Container(
                          width: 44,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${currentRawValue.toStringAsFixed(0)}',
                                    style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: currentRawValue > 0 ? AppTheme.textPrimary : Colors.transparent),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  ScopyBar(heightFactor: calculatedHeightFactor, barColor: barColor, maxCanvasHeight: constraints.maxHeight - 16),
                                ],
                              );
                            }
                          ),
                        );
                      }),
                    ),
                  ),
                  const Divider(height: 12, thickness: 1, color: AppTheme.border),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: (labels ?? []).map((label) => Container(
                      width: 44,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
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
          ),
        ),
      ],
    );
  }
}

class ScopyBar extends StatelessWidget {
  final double heightFactor;
  final Color barColor;
  final double maxCanvasHeight;

  const ScopyBar({super.key, required this.heightFactor, required this.barColor, required this.maxCanvasHeight});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: maxCanvasHeight * heightFactor.clamp(0.02, 1.0),
      child: Container(
        decoration: BoxDecoration(
          color: barColor.withOpacity(0.85),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ),
    );
  }
}

class SparklineMiniPainter extends CustomPainter {
  final Color color;
  final List<double> values;

  SparklineMiniPainter({required this.color, required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    if (values == null || values.isEmpty) return;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double dx = size.width / (values.length > 1 ? values.length - 1 : 1);

    for (int i = 0; i < values.length; i++) {
      final double x = i * dx;
      final double y = size.height - (values[i].clamp(0.0, 1.0) * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SparklineMiniPainter oldDelegate) => true;
}