import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/auth_notifier.dart';
import '../auth/auth_state.dart';
import '../services/beneficiary_preference.dart';
import '../services/onboarding_preference.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/privacy_screen.dart';
import '../../features/auth/presentation/screens/login_or_create_screen.dart';
import '../../features/auth/presentation/screens/pin_screen.dart';
import '../../features/beneficiary/presentation/screens/beneficiary_intro_screen.dart';
import '../../features/beneficiary/presentation/screens/evaluation_screen.dart';
import '../../features/beneficiary/presentation/screens/beneficiary_home_screen.dart';
import '../../features/beneficiary/data/datasources/report_remote_datasource.dart';
import '../../features/beneficiary/presentation/screens/bilans_list_screen.dart';
import '../../features/beneficiary/presentation/screens/report_detail_screen.dart';
import '../../features/beneficiary/presentation/screens/reports_tab_screen.dart';
import '../../features/beneficiary/presentation/screens/coming_soon_screens.dart';
import '../../features/beneficiary/presentation/screens/qr_screens.dart';
import '../../features/field_agent/presentation/screens/field_agent_home_screen.dart';
import '../../features/field_agent/presentation/screens/field_agent_qr_screen.dart';
import '../../features/field_agent/presentation/screens/field_agent_assisted_eval_screen.dart';
import '../../features/ambassador/presentation/screens/ambassador_home_screen.dart';
import 'route_names.dart';

part 'app_router.g.dart';

/// Routes accessibles lorsqu'authentifié en tant que bénéficiaire
const _beneficiaryRoutes = [
  RouteNames.beneficiaryIntro,
  RouteNames.beneficiaryEvaluation,
  RouteNames.beneficiaryHome,
  RouteNames.beneficiaryBilans,
  RouteNames.beneficiaryReportDetail,
  RouteNames.beneficiaryDepistage,
  RouteNames.beneficiaryConseiller,
  RouteNames.beneficiaryQr,
];

/// Routes accessibles à l'ambassador
const _ambassadorRoutes = [
  RouteNames.ambassadorHome,
  RouteNames.ambassadorQr,
  RouteNames.ambassadorDepistage,
  RouteNames.ambassadorConseiller,
];

/// Routes accessibles à l'agent de terrain
const _fieldAgentRoutes = [
  RouteNames.fieldAgentHome,
  RouteNames.fieldAgentQr,
  RouteNames.fieldAgentAssistedEval,
];

/// Routes accessibles à tous les rôles authentifiés (ex. évaluation assistée)
const _sharedAuthRoutes = [
  RouteNames.beneficiaryEvaluation,
];

@riverpod
GoRouter appRouter(Ref ref) {
  final authAsync = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    redirect: (context, state) async {
      final loc = state.matchedLocation;
      final isLoading = authAsync.isLoading || authAsync.isRefreshing;
      final authState = authAsync.valueOrNull;

      // Chargement → splash
      if (isLoading) {
        return loc == RouteNames.splash ? null : RouteNames.splash;
      }

      // Onboarding + privacy : toujours accessibles
      if (loc == RouteNames.onboarding || loc == RouteNames.privacy) {
        return null;
      }

      // PIN requis → forcer /pin
      if (authState is AuthStatePinRequired) {
        return loc == RouteNames.pin ? null : RouteNames.pin;
      }

      // Non authentifié
      if (authState == null || authState is AuthStateUnauthenticated) {
        if (loc == RouteNames.loginOrCreate) return null;
        final seen = await OnboardingPreference.hasSeen();
        return seen ? RouteNames.loginOrCreate : RouteNames.onboarding;
      }

      // Authentifié
      if (authState is AuthStateAuthenticated) {
        // Bloquer auth screens
        if (loc == RouteNames.pin || loc == RouteNames.loginOrCreate) {
          return _homeForRole(authState.user.role);
        }

        // Bénéficiaire
        if (authState.user.role == UserRole.beneficiary) {
          final hasStarted = await BeneficiaryPreference.hasStartedEvaluation(
            authState.user.id,
          );
          // Intro inaccessible une fois l'évaluation démarrée
          if (loc == RouteNames.beneficiaryIntro && hasStarted) {
            return RouteNames.beneficiaryHome;
          }
          if (_beneficiaryRoutes.contains(loc)) return null;
          // Routage par défaut
          return hasStarted
              ? RouteNames.beneficiaryHome
              : RouteNames.beneficiaryIntro;
        }

        // Ambassador
        if (authState.user.role == UserRole.ambassador) {
          if (_ambassadorRoutes.contains(loc) ||
              _sharedAuthRoutes.contains(loc)) { return null; }
          return RouteNames.ambassadorHome;
        }

        // Field agent
        if (authState.user.role == UserRole.fieldAgent) {
          if (_fieldAgentRoutes.contains(loc) ||
              _sharedAuthRoutes.contains(loc)) { return null; }
          return RouteNames.fieldAgentHome;
        }

        // Autres rôles
        final home = _homeForRole(authState.user.role);
        if (loc == home || _sharedAuthRoutes.contains(loc)) return null;
        return home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        name: RouteNames.splash,
        builder: (context, routeState) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        name: RouteNames.onboarding,
        builder: (context, routeState) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteNames.privacy,
        name: RouteNames.privacy,
        builder: (context, routeState) => const PrivacyScreen(),
      ),
      GoRoute(
        path: RouteNames.loginOrCreate,
        name: RouteNames.loginOrCreate,
        builder: (context, routeState) => const LoginOrCreateScreen(),
      ),
      GoRoute(
        path: RouteNames.pin,
        name: RouteNames.pin,
        builder: (context, state) {
          final pinState = state.extra as AuthStatePinRequired?;
          return pinState != null
              ? PinScreen(sessionToken: pinState.sessionToken, hasPin: pinState.hasPin)
              : const _PinScreenFromProvider();
        },
      ),
      // Bénéficiaire
      GoRoute(
        path: RouteNames.beneficiaryIntro,
        name: RouteNames.beneficiaryIntro,
        builder: (context, routeState) => const BeneficiaryIntroScreen(),
      ),
      GoRoute(
        path: RouteNames.beneficiaryEvaluation,
        name: RouteNames.beneficiaryEvaluation,
        builder: (context, routeState) => EvaluationScreen(
          subjectId: routeState.extra as String?,
        ),
      ),
      GoRoute(
        path: RouteNames.beneficiaryHome,
        name: RouteNames.beneficiaryHome,
        builder: (context, routeState) => const BeneficiaryHomeScreen(),
      ),
      GoRoute(
        path: RouteNames.beneficiaryBilans,
        name: RouteNames.beneficiaryBilans,
        builder: (context, routeState) => const BilansListScreen(),
      ),
      GoRoute(
        path: RouteNames.beneficiaryReportDetail,
        name: RouteNames.beneficiaryReportDetail,
        builder: (context, routeState) {
          final id = int.parse(routeState.pathParameters['id']!);
          final extra = routeState.extra as ReportSummary?;
          return ReportDetailScreen(reportId: id, initialData: extra);
        },
      ),
      GoRoute(
        path: RouteNames.beneficiaryDepistage,
        name: RouteNames.beneficiaryDepistage,
        builder: (context, routeState) => const DepistageProximiteScreen(),
      ),
      GoRoute(
        path: RouteNames.beneficiaryConseiller,
        name: RouteNames.beneficiaryConseiller,
        builder: (context, routeState) => const ConseillerScreen(),
      ),
      GoRoute(
        path: RouteNames.beneficiaryQr,
        name: RouteNames.beneficiaryQr,
        builder: (context, routeState) => const QrHubScreen(),
      ),
      // Autres rôles
      GoRoute(
        path: RouteNames.fieldAgentHome,
        name: RouteNames.fieldAgentHome,
        builder: (context, routeState) => const FieldAgentHomeScreen(),
      ),
      GoRoute(
        path: RouteNames.fieldAgentQr,
        name: RouteNames.fieldAgentQr,
        builder: (context, routeState) => const FieldAgentQrScreen(),
      ),
      GoRoute(
        path: RouteNames.fieldAgentAssistedEval,
        name: RouteNames.fieldAgentAssistedEval,
        builder: (context, routeState) =>
            const FieldAgentAssistedEvalScreen(),
      ),
      GoRoute(
        path: RouteNames.ambassadorHome,
        name: RouteNames.ambassadorHome,
        builder: (context, routeState) => const AmbassadorHomeScreen(),
      ),
      GoRoute(
        path: RouteNames.ambassadorQr,
        name: RouteNames.ambassadorQr,
        builder: (context, routeState) => const QrHubScreen(),
      ),
      GoRoute(
        path: RouteNames.ambassadorDepistage,
        name: RouteNames.ambassadorDepistage,
        builder: (context, routeState) => const DepistageProximiteScreen(),
      ),
      GoRoute(
        path: RouteNames.ambassadorConseiller,
        name: RouteNames.ambassadorConseiller,
        builder: (context, routeState) => const ConseillerScreen(),
      ),
    ],
  );
}

String _homeForRole(UserRole role) => switch (role) {
      UserRole.beneficiary => RouteNames.beneficiaryIntro,
      UserRole.fieldAgent => RouteNames.fieldAgentHome,
      UserRole.ambassador => RouteNames.ambassadorHome,
    };

class _PinScreenFromProvider extends ConsumerWidget {
  const _PinScreenFromProvider();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider).valueOrNull;
    if (authState is AuthStatePinRequired) {
      return PinScreen(sessionToken: authState.sessionToken, hasPin: authState.hasPin);
    }
    return const SizedBox.shrink();
  }
}
