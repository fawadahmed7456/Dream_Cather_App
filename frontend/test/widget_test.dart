import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safar_share/src/features/profile/presentation/widgets/user_avatar.dart';

/// Widget test for the default-avatar behaviour. Pumping the full [SafarShare]
/// app isn't feasible in a plain widget test (it needs Supabase/Firebase init
/// + DI), so we test the self-contained UserAvatar instead. The has-photo case
/// is intentionally not tested here because it builds a NetworkImage, which
/// the test HTTP stub fails — that needs a network-image mock.
void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

  group('UserAvatar', () {
    testWidgets('shows the wave default when there is no photo', (tester) async {
      await tester.pumpWidget(host(const UserAvatar(avatarUrl: null, radius: 40)));
      expect(find.text('👋'), findsOneWidget);
    });

    testWidgets('treats a blank avatarUrl as no photo', (tester) async {
      await tester.pumpWidget(host(const UserAvatar(avatarUrl: '   ', radius: 40)));
      expect(find.text('👋'), findsOneWidget);
    });

    testWidgets('renders the overlay instead of the wave', (tester) async {
      await tester.pumpWidget(host(
        const UserAvatar(avatarUrl: null, radius: 40, overlay: Text('UP')),
      ));
      expect(find.text('UP'), findsOneWidget);
      expect(find.text('👋'), findsNothing);
    });
  });
}
