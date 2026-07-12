import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.id,
    required super.fullName,
    super.email,
    super.phone,
    super.avatar,
    super.dob,
    super.gender,
    super.provinceCode,
    super.districtCode,
    super.addressDetail,
    super.bio,
    super.reputationScore,
    super.donationCount,
    super.receivedCount,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    return UserModel(
      id: data['id']?.toString() ?? '',
      fullName: (data['full_name'] ?? data['name'] ?? 'Người dùng').toString(),
      email: data['email']?.toString(),
      phone: data['phone']?.toString(),
      avatar: (data['avatar_url'] ?? data['avatar'] ?? data['profile_picture'])
          ?.toString(),
      dob: _parseDate(data['date_of_birth'] ?? data['dob']),
      gender: data['gender']?.toString(),
      provinceCode: data['province_code']?.toString(),
      districtCode: data['district_code']?.toString(),
      addressDetail: (data['address'] ?? data['address_detail'])?.toString(),
      bio: data['bio']?.toString(),
      reputationScore: _toInt(data['reputation_score']),
      donationCount: _toInt(data['donation_count']),
      receivedCount: _toInt(data['received_count']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (fullName.isNotEmpty) 'full_name': fullName,
      if (avatar != null) 'avatar_url': avatar,
      if (dob != null && dob!.isNotEmpty) 'date_of_birth': dob,
      if (gender != null && gender!.isNotEmpty) 'gender': gender,
      if (provinceCode != null) 'province_code': provinceCode,
      if (districtCode != null) 'district_code': districtCode,
      if (addressDetail != null) 'address': addressDetail,
      if (bio != null) 'bio': bio,
    };
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static String? _parseDate(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    if (raw.contains('T')) {
      return raw.split('T').first;
    }
    return raw;
  }
}
