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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    
    return UserModel(
      id: data['id']?.toString() ?? '',
      fullName: data['full_name'] ?? data['name'] ?? 'Người dùng',
      email: data['email'],
      phone: data['phone'],
      avatar: data['avatar_url'] ?? data['avatar'] ?? data['profile_picture'],
      dob: data['date_of_birth'] ?? data['dob'],
      gender: data['gender'],
      provinceCode: data['province_code']?.toString(),
      districtCode: data['district_code']?.toString(),
      addressDetail: data['address'] ?? data['address_detail'],
      bio: data['bio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (fullName.isNotEmpty) 'full_name': fullName,
      if (avatar != null) 'avatar_url': avatar,
      if (dob != null) 'date_of_birth': dob,
      if (gender != null) 'gender': gender,
      if (provinceCode != null) 'province_code': provinceCode,
      if (districtCode != null) 'district_code': districtCode,
      if (addressDetail != null) 'address': addressDetail,
      if (bio != null) 'bio': bio,
    };
  }
}
