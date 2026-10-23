// import 'package:flutter_test/flutter_test.dart';
// import 'package:safar_share/src/features/reviews/data/repositories/reviews_repository.dart';

// void main() {
//   group('Review.fromJson', () {
//     test('parses a review with a nested reviewer', () {
//       final r = Review.fromJson({
//         'id': 'rv1',
//         'rating': 5,
//         'comment': 'Great driver',
//         'created_at': '2026-06-14T00:00:00Z',
//         'reviewer': {
//           'id': 'u1',
//           'full_name': 'Arslan',
//           'avatar_url': 'https://cdn/a.jpg',
//         },
//       });
//       expect(r.id, 'rv1');
//       expect(r.rating, 5);
//       expect(r.comment, 'Great driver');
//       expect(r.reviewerName, 'Arslan');
//       expect(r.reviewerAvatar, 'https://cdn/a.jpg');
//     });

//     test('does not throw on a null reviewer / missing fields (crash-regression)', () {
//       final r = Review.fromJson({});
//       expect(r.id, '');
//       expect(r.rating, 0);
//       expect(r.comment, '');
//       expect(r.reviewerName, '');
//       expect(r.reviewerAvatar, '');
//     });

//     test('trims whitespace-only comment to empty', () {
//       final r = Review.fromJson({'rating': 3, 'comment': '   '});
//       expect(r.comment, '');
//       expect(r.rating, 3);
//     });
//   });

//   group('ReviewResult', () {
//     test('holds the recomputed average + count', () {
//       const res = ReviewResult(ratingAvg: 4.33, ratingCount: 6);
//       expect(res.ratingAvg, 4.33);
//       expect(res.ratingCount, 6);
//     });
//   });
// }
