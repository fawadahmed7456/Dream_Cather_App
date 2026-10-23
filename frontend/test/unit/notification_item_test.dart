import 'package:flutter_test/flutter_test.dart';
import 'package:safar_share/src/features/notifications/data/repositories/notifications_repository.dart';

void main() {
  group('NotificationItem.fromRow', () {
    NotificationItem make(String type) => NotificationItem.fromRow({
          'id': 'n1',
          'type': type,
          'title': 't',
          'body': 'b',
          'read': false,
          'created_at': '2026-06-14T00:00:00Z',
        });

    test('maps notification types to the right tone', () {
      expect(make('booking_confirmed').tone, NotificationTone.success);
      expect(make('ride_completed').tone, NotificationTone.success);
      expect(make('trip_completed').tone, NotificationTone.success);
      expect(make('review_received').tone, NotificationTone.success);
      expect(make('booking_cancelled').tone, NotificationTone.cancelled);
      expect(make('ride_cancelled').tone, NotificationTone.cancelled);
      expect(make('booking_created').tone, NotificationTone.info);
      expect(make('ride_published').tone, NotificationTone.info);
      expect(make('something_unknown').tone, NotificationTone.info);
    });

    test('parses fields and the read flag', () {
      final n = NotificationItem.fromRow({
        'id': 'n1',
        'type': 'booking_created',
        'title': 'New booking',
        'body': 'Someone booked your ride',
        'read': true,
        'ride_id': 'r1',
        'created_at': '2026-06-14T00:00:00Z',
      });
      expect(n.id, 'n1');
      expect(n.title, 'New booking');
      expect(n.body, 'Someone booked your ride');
      expect(n.read, isTrue);
      expect(n.rideId, 'r1');
    });

    test('does not throw on an empty row (crash-regression)', () {
      final n = NotificationItem.fromRow({});
      expect(n.id, '');
      expect(n.read, isFalse);
      expect(n.rideId, isNull);
      expect(n.tone, NotificationTone.info);
    });

    test('copyWith toggles read without losing other fields', () {
      final n = make('booking_created').copyWith(read: true);
      expect(n.read, isTrue);
      expect(n.tone, NotificationTone.info);
    });
  });
}
