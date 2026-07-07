class Plan {
  final int id;
  final int gymId;
  final String name;
  final double price;
  final String durationType; // 'DAYS' or 'MONTHS'
  final int durationValue;

  const Plan({
    required this.id,
    required this.gymId,
    required this.name,
    required this.price,
    required this.durationType,
    required this.durationValue,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: int.parse(json['id'].toString()),
      gymId: int.parse(json['gym_id'].toString()),
      name: json['name'] as String,
      price: double.parse(json['price'].toString()),
      durationType: json['duration_type'] as String,
      durationValue: int.parse(json['duration_value'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'gym_id': gymId,
        'name': name,
        'price': price,
        'duration_type': durationType,
        'duration_value': durationValue,
      };

  // 🚀 FIXED: Overriding value equality handlers resolves DropdownButton assertion mismatches
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Plan &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          gymId == other.gymId &&
          name == other.name &&
          price == other.price &&
          durationValue == other.durationValue &&
          durationType == other.durationType;

  @override
  int get hashCode =>
      id.hashCode ^
      gymId.hashCode ^
      name.hashCode ^
      price.hashCode ^
      durationValue.hashCode ^
      durationType.hashCode;
}