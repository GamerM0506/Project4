class UserEntity {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? avatar;
  final String? dob;
  final String? gender;
  final String? provinceCode;
  final String? districtCode;
  final String? addressDetail;
  final String? bio;

  UserEntity({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.avatar,
    this.dob,
    this.gender,
    this.provinceCode,
    this.districtCode,
    this.addressDetail,
    this.bio,
  });
}
