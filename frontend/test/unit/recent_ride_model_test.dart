// import 'package:flutter_test/flutter_test.dart';
// import 'package:safar_share/src/features/home/data/models/recent_ride_model.dart';

// void main() {
//   group('RecentRideModel.fromRideRow', () {
//     test('parses a complete row', () {
//       final m = RecentRideModel.fromRideRow({
//         'id': 'r1',
//         'origin': 'Islamabad',
//         'destination': 'Lahore',
//         'departure_at': '2026-06-13T07:34:00Z',
//         'price_per_seat': 500,
//         'status': 'active',
//       });
//       expect(m.rideId, 'r1');
//       expect(m.from, 'Islamabad');
//       expect(m.to, 'Lahore');
//       expect(m.price, '500');
//       expect(m.status, 'Upcoming');
//       expect(m.isCompleted, isFalse);
//     });

//     test('does not throw on an empty/garbage row (crash-regression)', () {
//       final m = RecentRideModel.fromRideRow({});
//       expect(m.from, '—');
//       expect(m.to, '—');
//       expect(m.date, '—');
//       expect(m.price, isA<String>());
//       expect(m.rideId, isNull);
//       expect(m.isCompleted, isFalse);
//     });

//     test('maps status to friendly labels', () {
//       expect(RecentRideModel.fromRideRow({'status': 'completed'}).status, 'Completed');
//       expect(RecentRideModel.fromRideRow({'status': 'cancelled'}).status, 'Cancelled');
//       expect(RecentRideModel.fromRideRow({'status': 'active'}).status, 'Upcoming');
//       // Unknown status is capitalised, not dropped.
//       expect(RecentRideModel.fromRideRow({'status': 'boarding'}).status, 'Boarding');
//     });

//     test('isCompleted is true only for completed rides', () {
//       expect(RecentRideModel.fromRideRow({'status': 'completed'}).isCompleted, isTrue);
//       expect(RecentRideModel.fromRideRow({'status': 'active'}).isCompleted, isFalse);
//       expect(RecentRideModel.fromRideRow({'status': 'cancelled'}).isCompleted, isFalse);
//     });

//     test('an unparseable departure_at degrades to a dash, not a crash', () {
//       final m = RecentRideModel.fromRideRow({'departure_at': 'not-a-date'});
//       expect(m.date, '—');
//     });

//     test('formats thousands with a separator', () {
//       final m = RecentRideModel.fromRideRow({'price_per_seat': 1500});
//       expect(m.price, '1,500');
//     });
//   });
// }
