import 'package:equatable/equatable.dart';

/// User profile entity matching the Dream Catcher database schema
class UserProfile extends Equatable {
  final String id;
  final String username;
  final String email;
  final String? avatarUrl;
  final String? ethnicity;
  final String? gender;
  final String? sexualOrientation;
  final String? relationshipStatus;
  final DateTime? birthday;
  final String? personalityIe; // 'I' | 'E'
  final String? personalitySn; // 'S' | 'N'
  final String? personalityFt; // 'F' | 'T'
  final String? personalityPj; // 'P' | 'J'
  final String? educationLevel;
  final String? bio;
  final String? phoneNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.ethnicity,
    this.gender,
    this.sexualOrientation,
    this.relationshipStatus,
    this.birthday,
    this.personalityIe,
    this.personalitySn,
    this.personalityFt,
    this.personalityPj,
    this.educationLevel,
    this.bio,
    this.phoneNumber,
    this.createdAt,
    this.updatedAt,
  });

  /// Computed MBTI personality code (e.g., "ENFP", "INTJ")
  String? get mbtiCode {
    if (personalityIe == null ||
        personalitySn == null ||
        personalityFt == null ||
        personalityPj == null) {
      return null;
    }
    return '$personalityIe$personalitySn$personalityFt$personalityPj';
  }

  /// Computed age from birthday
  int? get age {
    if (birthday == null) return null;
    final now = DateTime.now();
    int years = now.year - birthday!.year;
    if (now.month < birthday!.month ||
        (now.month == birthday!.month && now.day < birthday!.day)) {
      years--;
    }
    return years;
  }

  UserProfile copyWith({
    String? id,
    String? username,
    String? email,
    String? avatarUrl,
    String? ethnicity,
    String? gender,
    String? sexualOrientation,
    String? relationshipStatus,
    DateTime? birthday,
    String? personalityIe,
    String? personalitySn,
    String? personalityFt,
    String? personalityPj,
    String? educationLevel,
    String? bio,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      ethnicity: ethnicity ?? this.ethnicity,
      gender: gender ?? this.gender,
      sexualOrientation: sexualOrientation ?? this.sexualOrientation,
      relationshipStatus: relationshipStatus ?? this.relationshipStatus,
      birthday: birthday ?? this.birthday,
      personalityIe: personalityIe ?? this.personalityIe,
      personalitySn: personalitySn ?? this.personalitySn,
      personalityFt: personalityFt ?? this.personalityFt,
      personalityPj: personalityPj ?? this.personalityPj,
      educationLevel: educationLevel ?? this.educationLevel,
      bio: bio ?? this.bio,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (ethnicity != null) 'ethnicity': ethnicity,
      if (gender != null) 'gender': gender,
      if (sexualOrientation != null) 'sexual_orientation': sexualOrientation,
      if (relationshipStatus != null)
        'relationship_status': relationshipStatus,
      if (birthday != null)
        'birthday':
            '${birthday!.year.toString().padLeft(4, '0')}-${birthday!.month.toString().padLeft(2, '0')}-${birthday!.day.toString().padLeft(2, '0')}',
      if (personalityIe != null) 'personality_ie': personalityIe,
      if (personalitySn != null) 'personality_sn': personalitySn,
      if (personalityFt != null) 'personality_ft': personalityFt,
      if (personalityPj != null) 'personality_pj': personalityPj,
      if (educationLevel != null) 'education_level': educationLevel,
      if (bio != null) 'bio': bio,
      if (phoneNumber != null) 'phone_number': phoneNumber,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic date) {
      if (date == null) return null;
      if (date is DateTime) return date;
      try {
        return DateTime.parse(date.toString());
      } catch (_) {
        return null;
      }
    }

    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      ethnicity: json['ethnicity'] as String?,
      gender: json['gender'] as String?,
      sexualOrientation: json['sexual_orientation'] as String?,
      relationshipStatus: json['relationship_status'] as String?,
      birthday: parseDate(json['birthday']),
      personalityIe: json['personality_ie'] as String?,
      personalitySn: json['personality_sn'] as String?,
      personalityFt: json['personality_ft'] as String?,
      personalityPj: json['personality_pj'] as String?,
      educationLevel: json['education_level'] as String?,
      bio: json['bio'] as String?,
      phoneNumber: json['phone_number'] as String?,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        avatarUrl,
        ethnicity,
        gender,
        sexualOrientation,
        relationshipStatus,
        birthday,
        personalityIe,
        personalitySn,
        personalityFt,
        personalityPj,
        educationLevel,
        bio,
        phoneNumber,
        createdAt,
        updatedAt,
      ];
}
