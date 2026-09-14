import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/tulkhuur_controller.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/app_enums.dart';
import '../../../shared/models/inspection.dart';
import '../../../shared/widgets/app_state_widgets.dart';
import '../../../shared/widgets/status_chip.dart';

class ComparisonScreen extends ConsumerWidget {
  const ComparisonScreen({required this.moveOutInspectionId, super.key});

  final String moveOutInspectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tulkhuurControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.comparison)),
      body: state.when(
        loading: () => const AppLoadingView(),
        error: (error, stack) => AppErrorView(
          error: error,
          onRetry: () => ref.invalidate(tulkhuurControllerProvider),
        ),
        data: (data) {
          final after = data.inspectionById(moveOutInspectionId);
          final before = after?.linkedMoveInId == null
              ? null
              : data.inspectionById(after!.linkedMoveInId!);
          if (after == null || before == null) {
            return const EmptyState(
              icon: Icons.compare_arrows_rounded,
              title: AppStrings.noComparison,
              description: AppStrings.moveInRequired,
            );
          }
          final comparisons = _buildComparisons(before, after);
          if (comparisons.isEmpty) {
            return const EmptyState(
              icon: Icons.compare_arrows_rounded,
              title: AppStrings.noComparison,
              description: AppStrings.noInspectionsDescription,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: comparisons.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _ComparisonCard(comparison: comparisons[index]),
          );
        },
      ),
    );
  }

  List<_ItemComparison> _buildComparisons(Inspection before, Inspection after) {
    final result = <_ItemComparison>[];
    for (final afterRoom in after.rooms) {
      final beforeRoom = _findRoom(before.rooms, afterRoom.name);
      if (beforeRoom == null) continue;
      for (final afterItem in afterRoom.items) {
        final beforeItem = _findItem(beforeRoom.items, afterItem.name);
        if (beforeItem == null) continue;
        result.add(
          _ItemComparison(
            roomName: afterRoom.name,
            before: beforeItem,
            after: afterItem,
            result: compareConditions(
              beforeItem.condition,
              afterItem.condition,
            ),
          ),
        );
      }
    }
    return result;
  }

  InspectionRoom? _findRoom(List<InspectionRoom> rooms, String name) {
    for (final room in rooms) {
      if (room.name == name) return room;
    }
    return null;
  }

  InspectionItem? _findItem(List<InspectionItem> items, String name) {
    for (final item in items) {
      if (item.name == name) return item;
    }
    return null;
  }
}

class _ItemComparison {
  const _ItemComparison({
    required this.roomName,
    required this.before,
    required this.after,
    required this.result,
  });

  final String roomName;
  final InspectionItem before;
  final InspectionItem after;
  final ComparisonResult result;
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.comparison});

  final _ItemComparison comparison;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final resultColor = switch (comparison.result) {
      ComparisonResult.newDamage || ComparisonResult.missing => t.rose,
      ComparisonResult.improved => t.emerald,
      ComparisonResult.unchanged => t.textMuted,
      ComparisonResult.notComparable => t.amber,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              comparison.before.name.toUpperCase(),
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(
              comparison.roomName,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ComparisonSide(
                    title: AppStrings.moveIn,
                    item: comparison.before,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ComparisonSide(
                    title: AppStrings.moveOut,
                    item: comparison.after,
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Text(
              '${AppStrings.result}: ${comparison.result.label}',
              style: TextStyle(color: resultColor, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonSide extends StatelessWidget {
  const _ComparisonSide({required this.title, required this.item});

  final String title;
  final InspectionItem item;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      ConditionChip(condition: item.condition),
      if (item.photos.isNotEmpty) ...[
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(item.photos.first.localPath),
            height: 110,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => SizedBox(
              height: 110,
              child: ColoredBox(
                color: context.tokens.surfaceMuted,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
        ),
      ],
    ],
  );
}
