import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/application/tulkhuur_controller.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/app_enums.dart';
import '../../../shared/models/inspection.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_state_widgets.dart';
import '../../../shared/widgets/status_chip.dart';

class InspectionDetailScreen extends ConsumerWidget {
  const InspectionDetailScreen({required this.inspectionId, super.key});

  final String inspectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tulkhuurControllerProvider);
    return state.when(
      loading: () => const Scaffold(body: AppLoadingView()),
      error: (error, stack) => Scaffold(
        body: AppErrorView(
          error: error,
          onRetry: () => ref.invalidate(tulkhuurControllerProvider),
        ),
      ),
      data: (data) {
        final inspection = data.inspectionById(inspectionId);
        if (inspection == null) {
          return const Scaffold(
            body: EmptyState(
              icon: Icons.fact_check_outlined,
              title: AppStrings.inspectionNotFound,
              description: AppStrings.noInspectionsDescription,
            ),
          );
        }
        final property = data.propertyById(inspection.propertyId);
        final editable =
            inspection.status == InspectionStatus.draft ||
            inspection.status == InspectionStatus.revisionRequested;
        return Scaffold(
          appBar: AppBar(
            leading: const AppBackButton(fallbackLocation: '/inspections'),
            title: const Text(AppStrings.inspectionDetails),
            actions: [
              if (editable)
                IconButton(
                  tooltip: AppStrings.edit,
                  onPressed: () =>
                      context.push('/inspections/${inspection.id}/edit'),
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property?.name ?? AppStrings.propertyNotFound,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 5),
                      Text(inspection.type.label),
                      const SizedBox(height: 10),
                      InspectionStatusChip(status: inspection.status),
                      const Divider(height: 28),
                      Text(
                        AppStrings.updatedAt(
                          DateFormat('yyyy.MM.dd HH:mm')
                              .format(inspection.updatedAt),
                        ),
                      ),
                      if (inspection.tenantName != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${AppStrings.tenantName}: ${inspection.tenantName}',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (inspection.revisionRequests.isNotEmpty) ...[
                const SizedBox(height: 14),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          AppStrings.recentRevision,
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(inspection.revisionRequests.last.message),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                AppStrings.roomsAndItems,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              ...inspection.rooms.map(
                (room) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ExpansionTile(
                      title: Text(
                        room.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(AppStrings.itemCount(room.items.length)),
                      children: room.items
                          .map((item) => _ItemSummary(item: item))
                          .toList(),
                    ),
                  ),
                ),
              ),
              if (inspection.meterReadings.isNotEmpty) ...[
                const SizedBox(height: 10),
                _SupplementSummary(
                  title: AppStrings.meters,
                  icon: Icons.speed_outlined,
                  values: inspection.meterReadings
                      .map(
                        (meter) =>
                            '${meter.type}: ${meter.reading} ${meter.unit}',
                      )
                      .toList(),
                ),
              ],
              if (inspection.keys.isNotEmpty) ...[
                const SizedBox(height: 10),
                _SupplementSummary(
                  title: AppStrings.keys,
                  icon: Icons.key_outlined,
                  values: inspection.keys
                      .map((key) => '${key.type}: ${key.quantity}')
                      .toList(),
                ),
              ],
              if (inspection.type == InspectionType.moveOut &&
                  inspection.linkedMoveInId != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/inspections/${inspection.id}/comparison'),
                  icon: const Icon(Icons.compare_rounded),
                  label: const Text(AppStrings.comparison),
                ),
              ],
              const SizedBox(height: 18),
              if (editable)
                FilledButton.icon(
                  onPressed: () =>
                      context.push('/inspections/${inspection.id}/edit'),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text(AppStrings.continueLabel),
                ),
              if (inspection.status == InspectionStatus.reviewRequired)
                _ReviewActions(inspection: inspection),
              if (inspection.status == InspectionStatus.approved ||
                  inspection.status == InspectionStatus.partiallyConfirmed)
                _ConfirmationActions(inspection: inspection),
              if (inspection.status == InspectionStatus.finalized) ...[
                const SizedBox(height: 6),
                FilledButton.icon(
                  onPressed: () => context.go('/acts'),
                  icon: const Icon(Icons.description_outlined),
                  label: const Text(AppStrings.handoverAct),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SupplementSummary extends StatelessWidget {
  const _SupplementSummary({
    required this.title,
    required this.icon,
    required this.values,
  });

  final String title;
  final IconData icon;
  final List<String> values;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          ...values.map(
            (value) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon),
              title: Text(value),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ItemSummary extends StatelessWidget {
  const _ItemSummary({required this.item});

  final InspectionItem item;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ConditionChip(condition: item.condition),
          ],
        ),
        if (item.notes.isNotEmpty) Text(item.notes),
        if (item.photos.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: item.photos.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(item.photos[index].localPath),
                  width: 86,
                  height: 86,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => SizedBox.square(
                    dimension: 86,
                    child: ColoredBox(
                      color: context.tokens.surfaceMuted,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        const Divider(),
      ],
    ),
  );
}

class _ReviewActions extends ConsumerWidget {
  const _ReviewActions({required this.inspection});

  final Inspection inspection;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        AppStrings.reviewActions,
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 10),
      FilledButton.icon(
        onPressed: () async {
          await ref
              .read(tulkhuurControllerProvider.notifier)
              .approve(inspection.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.inspectionApproved)),
            );
          }
        },
        icon: const Icon(Icons.check_circle_outline_rounded),
        label: const Text(AppStrings.approve),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: () => _showRevisionDialog(context, ref, true),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text(AppStrings.requestNewPhoto),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: () => _showRevisionDialog(context, ref, false),
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text(AppStrings.requestInformationEdit),
      ),
    ],
  );

  Future<void> _showRevisionDialog(
    BuildContext context,
    WidgetRef ref,
    bool requestsNewPhoto,
  ) async {
    final controller = TextEditingController();
    final send = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          requestsNewPhoto
              ? AppStrings.requestNewPhoto
              : AppStrings.requestInformationEdit,
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: AppStrings.revisionMessage,
            hintText: AppStrings.revisionMessageHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: AppTheme.dialogAction(context),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.sendRevision),
          ),
        ],
      ),
    );
    final message = controller.text.trim();
    controller.dispose();
    if (send != true || message.isEmpty) return;
    await ref
        .read(tulkhuurControllerProvider.notifier)
        .requestRevision(
          inspectionId: inspection.id,
          message: message,
          requestsNewPhoto: requestsNewPhoto,
        );
  }
}

class _ConfirmationActions extends ConsumerWidget {
  const _ConfirmationActions({required this.inspection});

  final Inspection inspection;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            AppStrings.confirmationNotice,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          _ConfirmationRow(
            title: AppStrings.ownerConfirmation,
            confirmed: inspection.ownerConfirmed,
          ),
          _ConfirmationRow(
            title: AppStrings.tenantConfirmation,
            confirmed: inspection.tenantConfirmed,
          ),
          const SizedBox(height: 12),
          if (!inspection.ownerConfirmed)
            FilledButton(
              onPressed: () => ref
                  .read(tulkhuurControllerProvider.notifier)
                  .confirm(inspectionId: inspection.id, asOwner: true),
              child: const Text(AppStrings.confirmAsOwner),
            ),
          if (!inspection.tenantConfirmed) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => ref
                  .read(tulkhuurControllerProvider.notifier)
                  .confirm(inspectionId: inspection.id, asOwner: false),
              child: const Text(AppStrings.confirmAsTenant),
            ),
          ],
        ],
      ),
    ),
  );
}

class _ConfirmationRow extends StatelessWidget {
  const _ConfirmationRow({required this.title, required this.confirmed});

  final String title;
  final bool confirmed;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(
      confirmed ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
      color: confirmed ? context.tokens.emerald : context.tokens.textFaint,
    ),
    title: Text(title),
    trailing: Text(
      confirmed ? AppStrings.confirmed : AppStrings.notConfirmed,
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
  );
}
