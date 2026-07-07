class Gym {
  final int id;
  final int ownerId;
  final String name;
  final bool isPrimary;

  const Gym({
    required this.id,
    required this.ownerId,
    required this.name,
    this.isPrimary = false,
  });

  factory Gym.fromJson(Map<String, dynamic> json) {
    return Gym(
      id: int.parse(json['id'].toString()),
      ownerId: int.parse(json['owner_id'].toString()),
      name: json['name'] as String,
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'name': name,
        'is_primary': isPrimary,
      };
}