class MemberPlan {
  final int id;
  final int gymId;
  final int memberId;
  final int planId;
  final DateTime startDate;
  final DateTime endDate;
  final double planPrice;
  final double amountPaid;
  final double amountDue;
  final bool isCurrent;

  const MemberPlan({
    required this.id,
    required this.gymId,
    required this.memberId,
    required this.planId,
    required this.startDate,
    required this.endDate,
    required this.planPrice,
    this.amountPaid = 0.0,
    this.amountDue = 0.0,
    this.isCurrent = true,
  });

  factory MemberPlan.fromJson(Map<String, dynamic> json) {
    return MemberPlan(
      id: int.parse(json['id'].toString()),
      gymId: int.parse(json['gym_id'].toString()),
      memberId: int.parse(json['member_id'].toString()),
      planId: int.parse(json['plan_id'].toString()),
      startDate: DateTime.parse(json['start_date'].toString()),
      endDate: DateTime.parse(json['end_date'].toString()),
      planPrice: double.parse(json['plan_price'].toString()),
      amountPaid: double.parse(json['amount_paid'].toString()),
      amountDue: double.parse(json['amount_due'].toString()),
      isCurrent: json['is_current'] as bool? ?? true,
    );
  }
}