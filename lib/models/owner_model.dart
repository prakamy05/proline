class Owner {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? photoUrl;
  final String language;
  final String currency;

  const Owner({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.photoUrl,
    this.language = 'en',
    this.currency = 'INR',
  });

  factory Owner.fromJson(Map<String, dynamic> json) {
    return Owner(
      id: int.parse(json['id'].toString()),
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      photoUrl: json['photo_url'] as String?,
      language: json['language'] as String? ?? 'en',
      currency: json['currency'] as String? ?? 'INR',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'photo_url': photoUrl,
        'language': language,
        'currency': currency,
      };
}