import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dating_app/services/storage_service.dart';
import 'package:dating_app/screens/auth/login_screen.dart';
import 'package:dating_app/screens/auth/register_screen.dart';
import 'package:dating_app/screens/swipe/swipe_screen.dart';
import 'package:dating_app/screens/swipe/matches_screen.dart';
import 'package:dating_app/screens/chat/chat_list_screen.dart';
import 'package:dating_app/screens/chat/chat_room_screen.dart';
import 'package:dating_app/screens/profile/profile_screen.dart';
import 'package:dating_app/screens/discover/discover_screen.dart';

class AppRouter {
  final StorageService storage;

  AppRouter({required this.storage});

  late final GoRouter router = GoRouter(
    initialLocation: '/swipe',
    redirect: _guard,
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            _ScaffoldWithBottomNav(child: child),
        routes: [
          GoRoute(
            path: '/swipe',
            name: 'swipe',
            builder: (context, state) => const SwipeScreen(),
          ),
          GoRoute(
            path: '/matches',
            name: 'matches',
            builder: (context, state) => const MatchesScreen(),
          ),
          GoRoute(
            path: '/chat',
            name: 'chat',
            builder: (context, state) => const ChatListScreen(),
          ),
          GoRoute(
            path: '/discover',
            name: 'discover',
            builder: (context, state) => const DiscoverScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/chat/:matchId',
        name: 'chatRoom',
        builder: (context, state) {
          final matchId = state.pathParameters['matchId']!;
          final name = state.uri.queryParameters['name'] ?? 'Chat';
          return ChatRoomScreen(matchId: matchId, recipientName: name);
        },
      ),
    ],
  );

  String? _guard(BuildContext context, GoRouterState state) {
    final isLoggedIn = storage.hasToken;
    final isAuthRoute =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (!isLoggedIn && !isAuthRoute) {
      return '/login';
    }
    if (isLoggedIn && isAuthRoute) {
      return '/swipe';
    }
    return null;
  }
}

class _ScaffoldWithBottomNav extends StatelessWidget {
  final Widget child;

  const _ScaffoldWithBottomNav({required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/swipe')) return 0;
    if (location.startsWith('/matches')) return 1;
    if (location.startsWith('/chat')) return 2;
    if (location.startsWith('/discover')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/swipe');
              break;
            case 1:
              context.go('/matches');
              break;
            case 2:
              context.go('/chat');
              break;
            case 3:
              context.go('/discover');
              break;
            case 4:
              context.go('/profile');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_fire_department_outlined),
            selectedIcon: Icon(Icons.local_fire_department),
            label: 'Swipe',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Matches',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
