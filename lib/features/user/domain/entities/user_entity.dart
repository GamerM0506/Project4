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
  final int reputationScore;
  final int donationCount;
  final int receivedCount;

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
    this.reputationScore = 0,
    this.donationCount = 0,
    this.receivedCount = 0,
  });

  UserEntity copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? avatar,
    String? dob,
    String? gender,
    String? provinceCode,
    String? districtCode,
    String? addressDetail,
    String? bio,
    int? reputationScore,
    int? donationCount,
    int? receivedCount,
  }) {
    return UserEntity(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      provinceCode: provinceCode ?? this.provinceCode,
      districtCode: districtCode ?? this.districtCode,
      addressDetail: addressDetail ?? this.addressDetail,
      bio: bio ?? this.bio,
      reputationScore: reputationScore ?? this.reputationScore,
      donationCount: donationCount ?? this.donationCount,
      receivedCount: receivedCount ?? this.receivedCount,
    );
  }

  String? get resolvedAvatarUrl {
    final value = avatar?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return value;
  }
}
