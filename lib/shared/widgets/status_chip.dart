import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../models/app_enums.dart';

class InspectionStatusChip extends StatelessWidget {
  const InspectionStatusChip({required this.status, super.key});

  final InspectionStatus status;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (background, foreground, border) = switch (status) {
      InspectionStatus.draft => (t.surfaceMuted, t.textMuted, t.border),
      InspectionStatus.reviewRequired ||
      InspectionStatus.partiallyConfirmed => (
        t.amberSoft,
        t.onAmberSoft,
        t.amberBorder,
      ),
      InspectionStatus.revisionRequested => (
        t.rose.withValues(alpha: 0.12),
        t.rose,
        t.rose.withValues(alpha: 0.3),
      ),
      InspectionStatus.approved || InspectionStatus.finalized => (
        t.emeraldSoft,
        t.onEmeraldSoft,
        t.emeraldBorder,
      ),
    };
    return _SoftChip(
      label: status.label,
      background: background,
      foreground: foreground,
      border: border,
    );
  }
}

class ConditionChip extends StatelessWidget {
  const ConditionChip({required this.condition, super.key});

  final InspectionCondition condition;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = switch (condition) {
      InspectionCondition.good => t.emerald,
      InspectionCondition.minorDamage => t.amber,
      InspectionCondition.damaged ||
      InspectionCondition.missing => t.rose,
      InspectionCondition.notApplicable => t.textMuted,
    };
    return _SoftChip(
      label: condition.label,
      background: color.withValues(alpha: 0.12),
      foreground: color,
      border: color.withValues(alpha: 0.28),
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({
    required this.label,
    required this.background,
    required this.foreground,
    required this.border,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color border;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: border),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: foreground,
      ),
    ),
  );
}
