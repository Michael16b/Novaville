import 'package:equatable/equatable.dart';

class UsefulInfo extends Equatable {
  const UsefulInfo({
    required this.cityHallName,
    required this.addressLine1,
    this.addressLine2,
    required this.postalCode,
    required this.city,
    this.phone,
    this.email,
    this.website,
    this.instagram,
    this.facebook,
    this.x,
    required this.openingHours,
    this.additionalInfo,
  });

  factory UsefulInfo.fromJson(Map<String, dynamic> json) {
    // backend uses snake_case for field names
    final rawOpeningHours =
        (json['opening_hours'] as Map<String, dynamic>? ?? {});

    return UsefulInfo(
      cityHallName: json['city_hall_name'] as String? ?? '',
      addressLine1: json['address_line1'] as String? ?? '',
      addressLine2: json['address_line2'] as String?,
      postalCode: json['postal_code'] as String? ?? '',
      city: json['city'] as String? ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      instagram: json['instagram'] as String?,
      facebook: json['facebook'] as String?,
      x: json['x'] as String?,
      openingHours: rawOpeningHours.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        ),
      ),
      additionalInfo: json['additional_info'] as String?,
    );
  }
  final String cityHallName;
  final String addressLine1;
  final String? addressLine2;
  final String postalCode;
  final String city;

  final String? phone;
  final String? email;
  final String? website;

  final String? instagram;
  final String? facebook;
  final String? x;

  final Map<String, List<String>> openingHours;

  final String? additionalInfo;

  Map<String, dynamic> toJson() {
    return {
      // snake_case for backend
      'city_hall_name': cityHallName,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'postal_code': postalCode,
      'city': city,
      'phone': phone,
      'email': email,
      'website': website,
      'instagram': instagram,
      'facebook': facebook,
      'x': x,
      'opening_hours': openingHours,
      'additional_info': additionalInfo,
    };
  }

  // =============================
  // CopyWith
  // =============================

  UsefulInfo copyWith({
    String? cityHallName,
    String? addressLine1,
    String? addressLine2,
    String? postalCode,
    String? city,
    String? phone,
    String? email,
    String? website,
    String? instagram,
    String? facebook,
    String? x,
    Map<String, List<String>>? openingHours,
    String? additionalInfo,
  }) {
    return UsefulInfo(
      cityHallName: cityHallName ?? this.cityHallName,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      postalCode: postalCode ?? this.postalCode,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      x: x ?? this.x,
      openingHours: openingHours ?? this.openingHours,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  // =============================
  // Equatable
  // =============================

  @override
  List<Object?> get props => [
    cityHallName,
    addressLine1,
    addressLine2,
    postalCode,
    city,
    phone,
    email,
    website,
    instagram,
    facebook,
    x,
    openingHours,
    additionalInfo,
  ];
}
