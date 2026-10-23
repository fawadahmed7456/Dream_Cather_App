import 'package:flutter_test/flutter_test.dart';
import 'package:dream_catcher/src/features/auth/data/models/user_profile.dart';

void main() {
  group('UserProfile Model Tests', () {
    test('parses from Json correctly', () {
      final json = {
        'id': 'u123',
        'username': 'dreamer',
        'email': 'dreamer@example.com',
        'gender': 'Female',
        'sexual_orientation': 'Heterosexual',
        'birthday': '2000-01-15T00:00:00.000',
        'ethnicity': 'Asian',
        'personality_ie': 'I',
        'personality_sn': 'N',
        'personality_ft': 'F',
        'personality_pj': 'P',
        'relationship_status': 'Single',
        'education_level': "Bachelor's",
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.id, 'u123');
      expect(profile.username, 'dreamer');
      expect(profile.email, 'dreamer@example.com');
      expect(profile.gender, 'Female');
      expect(profile.mbtiCode, 'INFP');
      expect(profile.relationshipStatus, 'Single');
      expect(profile.educationLevel, "Bachelor's");
    });

    test('calculates MBTI code correctly', () {
      const profile = UserProfile(
        id: 'u1',
        username: 'test',
        email: 'test@example.com',
        personalityIe: 'E',
        personalitySn: 'N',
        personalityFt: 'T',
        personalityPj: 'J',
      );
      expect(profile.mbtiCode, 'ENTJ');
    });

    test('serializes to Json correctly', () {
      const profile = UserProfile(
        id: 'u1',
        username: 'coder',
        email: 'coder@test.com',
        gender: 'Male',
        personalityIe: 'I',
        personalitySn: 'S',
        personalityFt: 'T',
        personalityPj: 'J',
      );
      final json = profile.toJson();
      expect(json['username'], 'coder');
      expect(json['email'], 'coder@test.com');
      expect(json['gender'], 'Male');
      expect(json['personality_ie'], 'I');
      expect(json['personality_sn'], 'S');
      expect(json['personality_ft'], 'T');
      expect(json['personality_pj'], 'J');
    });
  });
}
