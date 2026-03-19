import 'package:chereh_app/core/auth/auth_notifier.dart';
import 'package:chereh_app/core/auth/auth_state.dart';
import 'package:chereh_app/features/auth/presentation/screens/pin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthNotifier extends AuthNotifier {
  int submitPinCalls = 0;
  int logoutCalls = 0;

  @override
  Future<AuthState> build() async {
    return const AuthStateAuthenticated(
      AuthUser(
        id: 'beneficiary-1',
        name: 'Awa',
        phone: '+2250700000000',
        role: UserRole.beneficiary,
        token: 'token-1',
        gateRequired: true,
        secretSet: false,
      ),
    );
  }

  @override
  Future<void> submitPin({
    required String sessionToken,
    required String pin,
    required bool hasPin,
  }) async {
    submitPinCalls++;
    state = const AsyncValue.data(
      AuthStateAuthenticated(
        AuthUser(
          id: 'beneficiary-1',
          name: 'Awa',
          phone: '+2250700000000',
          role: UserRole.beneficiary,
          token: 'token-1',
          gateRequired: false,
          secretSet: true,
        ),
      ),
    );
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    state = const AsyncValue.data(AuthStateUnauthenticated());
  }
}

void main() {
  testWidgets(
    'creating a PIN from home logs the beneficiary out',
    (WidgetTester tester) async {
      final fake = FakeAuthNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => fake),
          ],
          child: const MaterialApp(
            home: PinScreen(sessionToken: 'token-1', hasPin: false),
          ),
        ),
      );

      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('4'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(fake.submitPinCalls, 1);
      expect(fake.logoutCalls, 1);
    },
  );
}
