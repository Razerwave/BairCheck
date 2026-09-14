import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/acts/presentation/acts_screen.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/comparison/presentation/comparison_screen.dart';
import '../../features/feedback/presentation/feedback_screen.dart';
import '../../features/home/presentation/add_hub_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/inspections/presentation/inspection_detail_screen.dart';
import '../../features/inspections/presentation/inspection_editor_screen.dart';
import '../../features/inspections/presentation/inspections_screen.dart';
import '../../features/inspections/presentation/start_inspection_screen.dart';
import '../../features/invitations/presentation/invite_screen.dart';
import '../../features/legal/presentation/privacy_policy_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/properties/presentation/property_detail_screen.dart';
import '../../features/properties/presentation/property_form_screen.dart';
import '../../shared/models/app_enums.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/app_state_widgets.dart';
import '../constants/app_strings.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inspections',
                builder: (context, state) => const InspectionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/add',
                builder: (context, state) => const AddHubScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/acts',
                builder: (context, state) => const ActsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/properties/new',
        builder: (context, state) => const PropertyFormScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/properties/:propertyId',
        builder: (context, state) => PropertyDetailScreen(
          propertyId: state.pathParameters['propertyId']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/properties/:propertyId/edit',
        builder: (context, state) =>
            PropertyFormScreen(propertyId: state.pathParameters['propertyId']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/properties/:propertyId/start/:inspectionType',
        builder: (context, state) => StartInspectionScreen(
          propertyId: state.pathParameters['propertyId']!,
          type: InspectionTypeX.fromDatabase(
            state.pathParameters['inspectionType']!,
          ),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/inspections/:inspectionId',
        builder: (context, state) => InspectionDetailScreen(
          inspectionId: state.pathParameters['inspectionId']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/inspections/:inspectionId/edit',
        builder: (context, state) => InspectionEditorScreen(
          inspectionId: state.pathParameters['inspectionId']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/inspections/:inspectionId/comparison',
        builder: (context, state) => ComparisonScreen(
          moveOutInspectionId: state.pathParameters['inspectionId']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/invite/:token',
        builder: (context, state) =>
            InviteScreen(token: state.pathParameters['token']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/feedback',
        builder: (context, state) => const FeedbackScreen(),
      ),
    ],
    errorBuilder: (context, state) => const Scaffold(
      body: EmptyState(
        icon: Icons.search_off_rounded,
        title: AppStrings.pageNotFound,
        description: AppStrings.unknownError,
      ),
    ),
  ),
);
