class Member {
  final int id;
  final int gymId;
  final String? membershipNumber;
  final String name;
  final String? photoUrl;
  final String? gender;
  final String phone;
  final String? email;
  final DateTime? dob;
  final String? address;
  final DateTime joinedDate;
  final double dueAmount;
  final String status; // ACTIVE, BLOCKED, FROZEN

  const Member({
    required this.id,
    required this.gymId,
    this.membershipNumber,
    required this.name,
    this.photoUrl,
    this.gender,
    required this.phone,
    this.email,
    this.dob,
    this.address,
    required this.joinedDate,
    this.dueAmount = 0.0,
    this.status = 'ACTIVE',
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: int.tryParse(json['id'].toString()) ?? 0,
      gymId: int.tryParse(json['gym_id'].toString()) ?? 0,
      membershipNumber: json['membership_number'] as String?,
      name: json['name'] as String? ?? 'Unnamed Member',
      photoUrl: json['photo_url'] as String?,
      gender: json['gender'] as String?,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      dob: json['dob'] != null ? DateTime.tryParse(json['dob'].toString()) : null,
      address: json['address'] as String?,
      joinedDate: json['joined_date'] != null 
          ? DateTime.parse(json['joined_date'].toString()) 
          : DateTime.now(),
      // 🛡️ Safe Resilient Parse: Handles whole integers or decimal string returns cleanly
      dueAmount: double.tryParse(json['due_amount'].toString()) ?? 0.0,
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'gym_id': gymId,
        'membership_number': membershipNumber,
        'name': name,
        'photo_url': photoUrl,
        'gender': gender,
        'phone': phone,
        'email': email,
        'dob': dob?.toIso8601String().substring(0, 10),
        'address': address,
        'joined_date': joinedDate.toIso8601String().substring(0, 10),
        'due_amount': dueAmount,
        'status': status,
      };
}