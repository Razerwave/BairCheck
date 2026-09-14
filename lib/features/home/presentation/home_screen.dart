import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/application/tulkhuur_controller.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/backend_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/app_enums.dart';
import '../../../shared/models/inspection.dart';
import '../../../shared/models/property.dart';
import '../../../shared/widgets/app_state_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(tulkhuurControllerProvider);
    final backend = ref.watch(backendServiceProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: appState.when(
          loading: () => const AppLoadingView(),
          error: (error, stackTrace) => AppErrorView(
            error: error,
            onRetry: () => ref.invalidate(tulkhuurControllerProvider),
          ),
          data: (data) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(tulkhuurControllerProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
              children: [
                _BrandHeader(backend: backend),
                const SizedBox(height: 16),
                _Greeting(backend: backend),
                const SizedBox(height: 14),
                _SyncBanner(backend: backend),
                const SizedBox(height: 12),
                _StatsCard(state: data),
                const SizedBox(height: 12),
                const _QuickActions(),
                const SizedBox(height: 20),
                _PropertiesSection(state: data),
                const SizedBox(height: 20),
                _RecentInspections(state: data),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- header ---

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.backend});

  final BackendService backend;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: t.emerald,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: t.emerald.withValues(alpha: 0.7),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.appName,
                    style: TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: t.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const _Pill(
                    label: AppStrings.proBadge,
                    kind: _PillKind.emerald,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                AppStrings.appTaglineLong,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1,
                  color: t.textFaint,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _SquareButton(
          icon: Icons.notifications_none_rounded,
          badge: true,
          tooltip: AppStrings.offline,
          onTap: () => context.push('/feedback'),
        ),
        const SizedBox(width: 8),
        _AvatarButton(backend: backend),
      ],
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.badge = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.border),
            boxShadow: t.subtleShadow,
          ),
          child: Stack(
            children: [
              Center(child: Icon(icon, size: 18, color: t.textMuted)),
              if (badge)
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: t.rose,
                      shape: BoxShape.circle,
                      border: Border.all(color: t.surface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.backend});

  final BackendService backend;

  String? get _initials {
    final email = backend.currentUser?.email;
    if (email == null || email.isEmpty) return null;
    final local = email.split('@').first;
    final parts = local.split(RegExp(r'[._-]')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0]).join();
    return (letters.isEmpty ? local[0] : letters).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final initials = _initials;
    return Tooltip(
      message: AppStrings.profile,
      child: InkWell(
        onTap: () => context.go('/profile'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.iconTile,
            borderRadius: BorderRadius.circular(12),
            boxShadow: t.subtleShadow,
          ),
          child: initials == null
              ? Icon(
                  Icons.person_outline_rounded,
                  size: 18,
                  color: t.onIconTile,
                )
              : Text(
                  initials,
                  style: TextStyle(
                    fontFamily: AppTheme.displayFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: t.onIconTile,
                  ),
                ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.backend});

  final BackendService backend;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final now = DateTime.now();
    final email = backend.currentUser?.email;
    final name = email?.split('@').first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: t.surfaceMuted,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: t.brand,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                AppStrings.todayDate(now.month, now.day),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: t.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name == null ? AppStrings.greeting : AppStrings.greetingWith(name),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }
}

class _SyncBanner extends ConsumerWidget {
  const _SyncBanner({required this.backend});

  final BackendService backend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final signedIn = backend.isConfigured && backend.currentUser != null;
    final status = ref.watch(syncStatusProvider);

    final (dot, title, detail, badge, badgeKind) = switch ((
      signedIn,
      status.hasError,
      status.pending,
    )) {
      (false, _, _) => (
        t.amber,
        AppStrings.offlineActive,
        AppStrings.offlineStored,
        AppStrings.localBadge,
        _PillKind.neutral,
      ),
      (true, true, _) => (
        t.rose,
        AppStrings.syncErrorMessage,
        AppStrings.offlineStored,
        AppStrings.syncErrorBadge,
        _PillKind.amber,
      ),
      (true, false, final pending) when pending > 0 => (
        t.amber,
        AppStrings.syncReady,
        AppStrings.syncPending(pending),
        AppStrings.syncPendingBadge,
        _PillKind.amber,
      ),
      (true, false, _) => (
        t.emerald,
        AppStrings.syncReady,
        AppStrings.syncedAll,
        AppStrings.syncedBadge,
        _PillKind.emerald,
      ),
    };

    return InkWell(
      onTap: signedIn
          ? () async {
              final outcome = await ref.read(syncServiceProvider).sync();
              ref.read(syncStatusProvider.notifier).report(outcome);
            }
          : () => context.push('/auth'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: badgeKind == _PillKind.emerald ? t.emeraldBorder : t.border,
          ),
          boxShadow: t.subtleShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: t.textPrimary,
                      ),
                    ),
                    TextSpan(
                      text: '  •  $detail',
                      style: TextStyle(fontSize: 11, color: t.textFaint),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _Pill(label: badge, kind: badgeKind),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ stats ---

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.state});

  final TulkhuurState state;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final confirmed = state.inspections
        .where(
          (i) =>
              i.status == InspectionStatus.finalized ||
              i.status == InspectionStatus.approved,
        )
        .length;
    final pending = state.inspections
        .where(
          (i) =>
              i.status == InspectionStatus.draft ||
              i.status == InspectionStatus.reviewRequired ||
              i.status == InspectionStatus.revisionRequested,
        )
        .length;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatTile(
              icon: Icons.apartment_rounded,
              label: AppStrings.statTotalProperties,
              value: state.properties.length,
              highlighted: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatTile(
              icon: Icons.verified_outlined,
              label: AppStrings.statConfirmed,
              value: confirmed,
              accent: t.emerald,
              accentSoft: t.emeraldSoft,
              accentBorder: t.emeraldBorder,
              accentStrong: t.onEmeraldSoft,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatTile(
              icon: Icons.schedule_rounded,
              label: AppStrings.statPending,
              value: pending,
              accent: t.amber,
              accentSoft: t.amberSoft,
              accentBorder: t.amberBorder,
              accentStrong: t.onAmberSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.highlighted = false,
    this.accent,
    this.accentSoft,
    this.accentBorder,
    this.accentStrong,
  });

  final IconData icon;
  final String label;
  final int value;
  final bool highlighted;
  final Color? accent;
  final Color? accentSoft;
  final Color? accentBorder;
  final Color? accentStrong;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final valueColor = highlighted ? Colors.white : accentStrong!;
    final labelColor = highlighted
        ? Colors.white.withValues(alpha: 0.75)
        : t.textMuted;
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 11, 9, 11),
      decoration: BoxDecoration(
        color: highlighted ? null : t.surface,
        gradient: highlighted
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: t.statTileGradient,
              )
            : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: highlighted ? Colors.transparent : t.border),
        boxShadow: highlighted ? t.cardShadow : t.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: highlighted
                      ? Colors.white.withValues(alpha: 0.16)
                      : accentSoft,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: highlighted
                        ? Colors.white.withValues(alpha: 0.18)
                        : accentBorder!,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 11,
                  color: highlighted ? Colors.white : accent,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.5,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.25,
                    color: labelColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$value',
            style: TextStyle(
              fontFamily: AppTheme.displayFont,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              height: 1,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------- quick actions ---

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final actions = <_QuickAction>[
      _QuickAction(
        icon: Icons.add_rounded,
        label: AppStrings.addProperty,
        background: t.iconTile,
        foreground: t.onIconTile,
        onTap: () => context.push('/properties/new'),
      ),
      _QuickAction(
        icon: Icons.fact_check_outlined,
        label: AppStrings.quickStartInspection,
        background: t.brandSoft,
        foreground: t.onBrandSoft,
        onTap: () => context.go('/add'),
      ),
      _QuickAction(
        icon: Icons.description_outlined,
        label: AppStrings.handoverAct,
        background: t.skySoft,
        foreground: t.sky,
        onTap: () => context.go('/acts'),
      ),
      _QuickAction(
        icon: Icons.history_rounded,
        label: AppStrings.inspectionHistory,
        background: t.amberSoft,
        foreground: t.amber,
        onTap: () => context.go('/inspections'),
      ),
    ];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final action in actions) ...[
            Expanded(child: action),
            if (action != actions.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.border),
          boxShadow: t.subtleShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: foreground),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                height: 1.15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
                color: t.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- properties ---

class _PropertiesSection extends StatelessWidget {
  const _PropertiesSection({required this.state});

  final TulkhuurState state;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppStrings.myProperties,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(width: 6),
            if (state.properties.isNotEmpty)
              _Pill(
                label: '${state.properties.length}',
                kind: _PillKind.neutral,
              ),
            const Spacer(),
            InkWell(
              onTap: () => context.push('/properties/new'),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.add_rounded, size: 15, color: t.brandStrong),
                    const SizedBox(width: 2),
                    Text(
                      AppStrings.addProperty,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: t.brandStrong,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (state.properties.isEmpty)
          Container(
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: t.border),
              boxShadow: t.cardShadow,
            ),
            child: EmptyState(
              icon: Icons.apartment_rounded,
              title: AppStrings.noProperties,
              description: AppStrings.noPropertiesDescription,
              actionLabel: AppStrings.addProperty,
              onAction: () => context.push('/properties/new'),
            ),
          )
        else
          for (final property in state.properties)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PropertyCard(
                property: property,
                inspections: state.inspectionsForProperty(property.id),
              ),
            ),
      ],
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.property, required this.inspections});

  final Property property;
  final List<Inspection> inspections;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final area = property.areaSquareMeters;
    final areaText = area % 1 == 0
        ? area.toInt().toString()
        : area.toStringAsFixed(1);
    final last = inspections.isEmpty
        ? null
        : inspections.reduce(
            (a, b) => a.updatedAt.isAfter(b.updatedAt) ? a : b,
          );
    return InkWell(
      onTap: () => context.push('/properties/${property.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.border),
          boxShadow: t.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: t.iconTile,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.apartment_rounded,
                    size: 24,
                    color: t.onIconTile,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              property.name,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _Pill(
                            label: inspections.isEmpty
                                ? AppStrings.needsInspection
                                : AppStrings.hasInspection,
                            kind: inspections.isEmpty
                                ? _PillKind.amber
                                : _PillKind.emerald,
                            dot: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 12,
                            color: t.textFaint,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              property.address,
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6, top: 2),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: t.textFaint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: t.border),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Chip(label: AppStrings.floorLabel(property.floor)),
                _Chip(label: AppStrings.areaLabel(areaText)),
                _Chip(label: property.furnishingType.label),
                if (inspections.isNotEmpty)
                  _Chip(
                    label: AppStrings.inspectionCount(inspections.length),
                    brand: true,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: t.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: last == null
                          ? t.textFaint
                          : _statusColor(last.status, t),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: last == null
                        ? Text(
                            AppStrings.noInspectionYet,
                            style: TextStyle(fontSize: 11, color: t.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${AppStrings.lastInspectionLabel}: ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: t.textMuted,
                                  ),
                                ),
                                TextSpan(
                                  text: AppStrings.daysAgo(
                                    DateTime.now()
                                        .difference(last.updatedAt)
                                        .inDays,
                                  ),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: t.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                  Text(
                    AppStrings.details,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: t.brandStrong,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: t.brandStrong,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------ recent inspections ---

class _RecentInspections extends StatelessWidget {
  const _RecentInspections({required this.state});

  final TulkhuurState state;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (state.inspections.isEmpty) return const SizedBox.shrink();
    final recent = [...state.inspections]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final items = recent.take(3).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppStrings.recentInspections,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            InkWell(
              onTap: () => context.go('/inspections'),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  AppStrings.viewAll,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: t.brandStrong,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: t.border),
            boxShadow: t.cardShadow,
          ),
          child: Column(
            children: [
              for (final inspection in items) ...[
                _InspectionRow(
                  inspection: inspection,
                  property: state.propertyById(inspection.propertyId),
                ),
                if (inspection != items.last)
                  Container(height: 1, color: t.border),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InspectionRow extends StatelessWidget {
  const _InspectionRow({required this.inspection, required this.property});

  final Inspection inspection;
  final Property? property;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = _statusColor(inspection.status, t);
    final photos = inspection.rooms
        .expand((room) => room.items)
        .expand((item) => item.photos)
        .length;
    final date = inspection.updatedAt;
    final dateText =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.'
        '${date.day.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: () => context.push('/inspections/${inspection.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${property?.name ?? AppStrings.propertyUnit} • '
                    '${inspection.type.label}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: t.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$dateText • ${AppStrings.photoCount(photos)}',
                    style: TextStyle(fontSize: 10, color: t.textFaint),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _Pill(
              label: inspection.status.label,
              kind: _pillKindFor(inspection.status),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- shared ---

enum _PillKind { neutral, emerald, amber, brand }

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.kind, this.dot = false});

  final String label;
  final _PillKind kind;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (background, foreground, border) = switch (kind) {
      _PillKind.emerald => (t.emeraldSoft, t.onEmeraldSoft, t.emeraldBorder),
      _PillKind.amber => (t.amberSoft, t.onAmberSoft, t.amberBorder),
      _PillKind.brand => (t.brandSoft, t.onBrandSoft, t.brandSoftBorder),
      _PillKind.neutral => (t.surfaceMuted, t.textMuted, t.border),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.brand = false});

  final String label;
  final bool brand;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: brand ? t.brandSoft : t.surfaceMuted,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: brand ? t.brandSoftBorder : t.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: brand ? FontWeight.w600 : FontWeight.w500,
          color: brand ? t.onBrandSoft : t.textMuted,
        ),
      ),
    );
  }
}

Color _statusColor(InspectionStatus status, AppTokens t) => switch (status) {
  InspectionStatus.finalized || InspectionStatus.approved => t.emerald,
  InspectionStatus.reviewRequired ||
  InspectionStatus.partiallyConfirmed => t.amber,
  InspectionStatus.revisionRequested => t.rose,
  InspectionStatus.draft => t.textFaint,
};

_PillKind _pillKindFor(InspectionStatus status) => switch (status) {
  InspectionStatus.finalized || InspectionStatus.approved => _PillKind.emerald,
  InspectionStatus.reviewRequired ||
  InspectionStatus.partiallyConfirmed ||
  InspectionStatus.revisionRequested => _PillKind.amber,
  InspectionStatus.draft => _PillKind.neutral,
};
