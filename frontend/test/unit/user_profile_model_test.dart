// import 'package:flutter_test/flutter_test.dart';
// import 'package:safar_share/src/features/profile/data/models/profile_model.dart';

// void main() {
//   group('UserProfileModel.fromRow', () {
//     test('parses a complete row', () {
//       final m = UserProfileModel.fromRow({
//         'id': 'u1',
//         'full_name': 'Arslan',
//         'phone': '+923111539073',
//         'email': 'a@b.c',
//         'avatar_url': 'https://cdn/x.jpg',
//         'rating_avg': 4.5,
//       });
//       expect(m.id, 'u1');
//       expect(m.name, 'Arslan');
//       expect(m.phone, '+923111539073');
//       expect(m.email, 'a@b.c');
//       expect(m.avatarUrl, 'https://cdn/x.jpg');
//       expect(m.rating, 4.5);
//     });

//     test('defaults every field on an empty row (crash-regression)', () {
//       final m = UserProfileModel.fromRow({});
//       expect(m.id, '');
//       expect(m.name, '');
//       expect(m.phone, '');
//       expect(m.rating, 0);
//       expect(m.avatarUrl, isNull);
//     });

//     test('imageUrl returns the real avatar when present', () {
//       final m = UserProfileModel.fromRow({'id': 'u1', 'avatar_url': 'https://cdn/a.jpg'});
//       expect(m.imageUrl, 'https://cdn/a.jpg');
//     });

//     test('imageUrl falls back to a deterministic seeded URL when blank/null', () {
//       final none = UserProfileModel.fromRow({'id': 'u1'});
//       expect(none.imageUrl, contains('u1'));
//       final empty = UserProfileModel.fromRow({'id': 'u1', 'avatar_url': ''});
//       expect(empty.imageUrl, contains('picsum'));
//     });

//     test('copyWith can clear the avatar', () {
//       final m = UserProfileModel.fromRow({'id': 'u1', 'avatar_url': 'https://cdn/a.jpg'});
//       expect(m.copyWith(clearAvatarUrl: true).avatarUrl, isNull);
//     });
//   });
// }
