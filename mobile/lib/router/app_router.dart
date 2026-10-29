import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/semillero_membership.dart';
import '../providers/session_provider.dart';
import '../screens/accounts/accounts_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/contributions/contribution_form_screen.dart';
import '../screens/contributions/contributions_screen.dart';
import '../screens/expenses/expense_form_screen.dart';
import '../screens/expenses/expenses_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/invite/invite_screen.dart';
import '../screens/members/member_detail_screen.dart';
import '../screens/members/member_form_screen.dart';
import '../screens/members/members_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/semilleros/create_semillero_screen.dart';
import '../screens/semilleros/join_semillero_screen.dart';
import '../screens/semilleros/pending_request_screen.dart';
import '../screens/semilleros/semilleros_screen.dart';
import '../screens/splash/splash_screen.dart';

/// Rutas que requieren un semillero activo.
const Set<String> _semilleroRoutes = <String>{'/home', '/accounts', '/invite'};

/// Prefijos de rutas que requieren un semillero activo.
const List<String> _semilleroPrefixes = <String>[
  '/members',
  '/contributions',
  '/expenses',
];

/// Rutas exclusivas del tesorero (la API también lo valida con 403).
const Set<String> _treasurerRoutes = <String>{
  '/accounts',
  '/invite',
  '/members/new',
  '/contributions/new',
  '/expenses/new',
};

bool _isTreasurerRoute(String location) {
  if (_treasurerRoutes.contains(location)) return true;
  // Editar integrante: /members/:id/edit
  return location.startsWith('/members/') && location.endsWith('/edit');
}

class AppRouter {
  AppRouter({required SessionProvider session})
    : router = GoRouter(
        initialLocation: '/splash',
        refreshListenable: session,
        redirect: (BuildContext context, GoRouterState state) {
          final String location = state.matchedLocation;
          final SessionStatus status = session.status;

          if (status == SessionStatus.bootstrapping) {
            return location == '/splash' ? null : '/splash';
          }

          if (status == SessionStatus.unauthenticated) {
            const Set<String> publicRoutes = <String>{
              '/welcome',
              '/login',
              '/register',
            };
            if (publicRoutes.contains(location)) return null;
            return session.notice != null ? '/login' : '/welcome';
          }

          const Set<String> authRoutes = <String>{
            '/splash',
            '/welcome',
            '/login',
            '/register',
          };
          if (authRoutes.contains(location)) {
            return session.hasActiveSemillero ? '/home' : '/semilleros';
          }

          final bool needsSemillero =
              _semilleroRoutes.contains(location) ||
              _semilleroPrefixes.any(location.startsWith);
          if (!session.hasActiveSemillero && needsSemillero) {
            return '/semilleros';
          }

          if (session.hasActiveSemillero &&
              !session.isTesorero &&
              _isTreasurerRoute(location)) {
            return '/home';
          }

          return null;
        },
        routes: <RouteBase>[
          GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
          GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
          GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
          GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
          GoRoute(
            path: '/semilleros',
            builder: (_, _) => const SemillerosScreen(),
          ),
          GoRoute(
            path: '/semilleros/create',
            builder: (_, _) => const CreateSemilleroScreen(),
          ),
          GoRoute(
            path: '/semilleros/join',
            builder: (_, _) => const JoinSemilleroScreen(),
          ),
          GoRoute(
            path: '/semilleros/pending',
            builder: (_, GoRouterState state) {
              final Object? extra = state.extra;
              return PendingRequestScreen(
                membership: extra is SemilleroMembership ? extra : null,
              );
            },
          ),
          GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
          GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          GoRoute(path: '/accounts', builder: (_, _) => const AccountsScreen()),
          GoRoute(path: '/invite', builder: (_, _) => const InviteScreen()),
          GoRoute(
            path: '/members',
            builder: (_, _) => const MembersScreen(),
            routes: <RouteBase>[
              GoRoute(path: 'new', builder: (_, _) => const MemberFormScreen()),
              GoRoute(
                path: ':id',
                builder: (_, GoRouterState state) =>
                    MemberDetailScreen(memberId: state.pathParameters['id']!),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'edit',
                    builder: (_, GoRouterState state) =>
                        MemberFormScreen(memberId: state.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/contributions',
            builder: (_, _) => const ContributionsScreen(),
            routes: <RouteBase>[
              GoRoute(
                path: 'new',
                builder: (_, _) => const ContributionFormScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/expenses',
            builder: (_, _) => const ExpensesScreen(),
            routes: <RouteBase>[
              GoRoute(
                path: 'new',
                builder: (_, _) => const ExpenseFormScreen(),
              ),
            ],
          ),
        ],
      );

  final GoRouter router;
}
