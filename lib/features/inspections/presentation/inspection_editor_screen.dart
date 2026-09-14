import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/application/tulkhuur_controller.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/photo_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/app_enums.dart';
import '../../../shared/models/inspection.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_state_widgets.dart';

class InspectionEditorScreen extends ConsumerWidget {
  const InspectionEditorScreen({required this.inspectionId, super.key});

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
            title: Text(inspection.type.label),
            actions: [
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text(AppStrings.draftSaved)),
                  );
                  context.pushReplacement('/inspections/${inspection.id}');
                },
                child: const Text(AppStrings.draftSave),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    child: Icon(Icons.apartment_rounded),
                  ),
                  title: Text(
                    property?.name ?? AppStrings.propertyNotFound,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(inspection.fillMethod.label),
                ),
              ),
              if (inspection.revisionRequests.isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          AppStrings.revisionsRequired,
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.roomsAndItems,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (editable)
                    TextButton.icon(
                      onPressed: () => _addRoom(context, ref),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text(AppStrings.addRoom),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ...inspection.rooms.map(
                (room) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: ExpansionTile(
                      initiallyExpanded: inspection.rooms.first.id == room.id,
                      title: Text(
                        room.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(AppStrings.itemCount(room.items.length)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (editable && room.isCustom)
                            IconButton(
                              tooltip: AppStrings.delete,
                              onPressed: () => _removeRoom(context, ref, room),
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          const Icon(Icons.expand_more_rounded),
                        ],
                      ),
                      children: [
                        const Divider(height: 1),
                        ...room.items.map(
                          (item) => _ItemEditor(
                            key: ValueKey(item.id),
                            inspectionId: inspection.id,
                            roomId: room.id,
                            item: item,
                            editable: editable,
                          ),
                        ),
                        if (editable)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: OutlinedButton.icon(
                              onPressed: () => _addItem(context, ref, room.id),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text(AppStrings.addItem),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _SupplementSection(
                title: AppStrings.meters,
                addLabel: AppStrings.addMeter,
                editable: editable,
                onAdd: () => _addMeter(context, ref),
                children: inspection.meterReadings
                    .map(
                      (meter) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.speed_outlined),
                        title: Text(meter.type),
                        subtitle: Text('${meter.reading} ${meter.unit}'),
                        trailing: editable
                            ? IconButton(
                                tooltip: AppStrings.delete,
                                onPressed: () =>
                                    _removeMeter(context, ref, meter.id),
                                icon: const Icon(Icons.delete_outline_rounded),
                              )
                            : null,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              _SupplementSection(
                title: AppStrings.keys,
                addLabel: AppStrings.addKey,
                editable: editable,
                onAdd: () => _addKey(context, ref),
                children: inspection.keys
                    .map(
                      (key) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.key_outlined),
                        title: Text(key.type),
                        subtitle: Text(key.quantity.toString()),
                        trailing: editable
                            ? IconButton(
                                tooltip: AppStrings.delete,
                                onPressed: () =>
                                    _removeKey(context, ref, key.id),
                                icon: const Icon(Icons.delete_outline_rounded),
                              )
                            : null,
                      ),
                    )
                    .toList(),
              ),
              if (editable) ...[
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => _submit(context, ref),
                  icon: const Icon(Icons.send_outlined),
                  label: const Text(AppStrings.submitForReview),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () =>
                      context.pushReplacement('/inspections/${inspection.id}'),
                  child: const Text(AppStrings.continueLater),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _addRoom(BuildContext context, WidgetRef ref) async {
    final name = await _textDialog(
      context,
      title: AppStrings.addRoom,
      label: AppStrings.roomName,
    );
    if (name == null || name.trim().isEmpty) return;
    await ref
        .read(tulkhuurControllerProvider.notifier)
        .addRoom(inspectionId, name);
  }

  Future<void> _removeRoom(
    BuildContext context,
    WidgetRef ref,
    InspectionRoom room,
  ) async {
    final confirmed = await _confirmDialog(
      context,
      title: AppStrings.removeRoomQuestion,
    );
    if (!confirmed) return;
    await ref
        .read(tulkhuurControllerProvider.notifier)
        .removeRoom(inspectionId, room.id);
  }

  Future<void> _addItem(
    BuildContext context,
    WidgetRef ref,
    String roomId,
  ) async {
    final name = await _textDialog(
      context,
      title: AppStrings.addItem,
      label: AppStrings.itemName,
    );
    if (name == null || name.trim().isEmpty) return;
    await ref
        .read(tulkhuurControllerProvider.notifier)
        .addItem(inspectionId, roomId, name);
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirmDialog(
      context,
      title: AppStrings.submitInspectionQuestion,
      description: AppStrings.submitInspectionDescription,
    );
    if (!confirmed) return;
    await ref
        .read(tulkhuurControllerProvider.notifier)
        .submitForReview(inspectionId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.submittedForReview)),
    );
    context.pushReplacement('/inspections/$inspectionId');
  }

  Future<void> _addMeter(BuildContext context, WidgetRef ref) async {
    final result = await _meterDialog(context);
    if (result == null) return;
    await ref
        .read(tulkhuurControllerProvider.notifier)
        .addMeterReading(
          inspectionId: inspectionId,
          type: result.type,
          reading: result.reading,
          unit: result.unit,
          notes: result.notes,
        );
  }

  Future<void> _removeMeter(
    BuildContext context,
    WidgetRef ref,
    String meterId,
  ) async {
    if (!await _confirmDialog(context, title: AppStrings.removeMeterQuestion)) {
      return;
    }
    await ref
        .read(tulkhuurControllerProvider.notifier)
        .removeMeterReading(inspectionId, meterId);
  }

  Future<void> _addKey(BuildContext context, WidgetRef ref) async {
    final result = await _keyDialog(context);
    if (result == null) return;
    await ref
        .read(tulkhuurControllerProvider.notifier)
        .addKey(
          inspectionId: inspectionId,
          type: result.type,
          quantity: result.quantity,
          notes: result.notes,
        );
  }

  Future<void> _removeKey(
    BuildContext context,
    WidgetRef ref,
    String keyId,
  ) async {
    if (!await _confirmDialog(context, title: AppStrings.removeKeyQuestion)) {
      return;
    }
    await ref
        .read(tulkhuurControllerProvider.notifier)
        .removeKey(inspectionId, keyId);
  }
}

class _SupplementSection extends StatelessWidget {
  const _SupplementSection({
    required this.title,
    required this.addLabel,
    required this.editable,
    required this.onAdd,
    required this.children,
  });

  final String title;
  final String addLabel;
  final bool editable;
  final VoidCallback onAdd;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          ...children,
          if (editable)
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(addLabel),
            ),
        ],
      ),
    ),
  );
}

class _ItemEditor extends ConsumerStatefulWidget {
  const _ItemEditor({
    required this.inspectionId,
    required this.roomId,
    required this.item,
    required this.editable,
    super.key,
  });

  final String inspectionId;
  final String roomId;
  final InspectionItem item;
  final bool editable;

  @override
  ConsumerState<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends ConsumerState<_ItemEditor> {
  late final TextEditingController _notesController;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.item.notes);
  }

  @override
  void didUpdateWidget(covariant _ItemEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_notesController.selection.isValid &&
        _notesController.text != widget.item.notes) {
      _notesController.text = widget.item.notes;
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.item.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            if (widget.editable && widget.item.isCustom)
              IconButton(
                tooltip: AppStrings.delete,
                onPressed: _removeItem,
                icon: const Icon(Icons.close_rounded),
              ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<InspectionCondition>(
          initialValue: widget.item.condition,
          decoration: const InputDecoration(labelText: AppStrings.condition),
          items: InspectionCondition.values
              .map(
                (condition) => DropdownMenuItem(
                  value: condition,
                  child: Text(condition.label),
                ),
              )
              .toList(),
          onChanged: widget.editable
              ? (condition) => _save(condition: condition)
              : null,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _notesController,
          enabled: widget.editable,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: AppStrings.notes,
            hintText: AppStrings.notesHint,
          ),
          onChanged: (_) {
            _saveTimer?.cancel();
            _saveTimer = Timer(
              const Duration(milliseconds: 450),
              () => _save(notes: _notesController.text),
            );
          },
        ),
        if (widget.item.photos.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.item.photos.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final photo = widget.item.photos[index];
                return _PhotoThumbnail(
                  photo: photo,
                  editable: widget.editable,
                  onRetry: () => ref
                      .read(tulkhuurControllerProvider.notifier)
                      .retryPhotoUpload(
                        inspectionId: widget.inspectionId,
                        roomId: widget.roomId,
                        itemId: widget.item.id,
                        photoId: photo.id,
                      ),
                  onRemove: () => _removePhoto(photo),
                );
              },
            ),
          ),
        ],
        if (widget.editable) ...[
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text(AppStrings.addPhoto),
          ),
        ],
        const Divider(height: 22),
      ],
    ),
  );

  Future<void> _save({InspectionCondition? condition, String? notes}) async {
    final latest = ref
        .read(tulkhuurControllerProvider)
        .value
        ?.inspectionById(widget.inspectionId)
        ?.rooms
        .where((room) => room.id == widget.roomId)
        .first
        .items
        .where((item) => item.id == widget.item.id)
        .first;
    if (latest == null) return;
    await ref
        .read(tulkhuurControllerProvider.notifier)
        .updateItem(
          inspectionId: widget.inspectionId,
          roomId: widget.roomId,
          item: latest.copyWith(
            condition: condition,
            notes: notes ?? _notesController.text,
          ),
        );
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text(AppStrings.takePhoto),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text(AppStrings.chooseFromGallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    try {
      final photo = await ref
          .read(photoServiceProvider)
          .pickAndPreserve(source);
      if (photo == null) return;
      await ref
          .read(tulkhuurControllerProvider.notifier)
          .addPhoto(
            inspectionId: widget.inspectionId,
            roomId: widget.roomId,
            itemId: widget.item.id,
            photo: photo,
          );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.photoPermissionError)),
      );
    }
  }

  Future<void> _removePhoto(EvidencePhoto photo) async {
    final confirmed = await _confirmDialog(
      context,
      title: AppStrings.removePhoto,
    );
    if (!confirmed) return;
    await ref
        .read(tulkhuurControllerProvider.notifier)
        .removePhoto(
          inspectionId: widget.inspectionId,
          roomId: widget.roomId,
          itemId: widget.item.id,
          photoId: photo.id,
        );
    await ref.read(photoServiceProvider).deletePreserved(photo);
  }

  Future<void> _removeItem() async {
    final confirmed = await _confirmDialog(
      context,
      title: AppStrings.removeItemQuestion,
    );
    if (!confirmed) return;
    await ref
        .read(tulkhuurControllerProvider.notifier)
        .removeItem(widget.inspectionId, widget.roomId, widget.item.id);
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({
    required this.photo,
    required this.editable,
    required this.onRetry,
    required this.onRemove,
  });

  final EvidencePhoto photo;
  final bool editable;
  final VoidCallback onRetry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 112,
    child: Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(photo.localPath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => ColoredBox(
              color: context.tokens.surfaceMuted,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
        Positioned(
          left: 4,
          bottom: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              photo.uploadStatus.label,
              style: const TextStyle(color: Colors.white, fontSize: 9),
            ),
          ),
        ),
        if (photo.uploadStatus == PhotoUploadStatus.failed)
          Positioned(
            right: 3,
            bottom: 3,
            child: IconButton.filledTonal(
              tooltip: AppStrings.retry,
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
            ),
          ),
        if (editable)
          Positioned(
            right: 3,
            top: 3,
            child: IconButton.filled(
              tooltip: AppStrings.removePhoto,
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ),
      ],
    ),
  );
}

Future<String?> _textDialog(
  BuildContext context, {
  required String title,
  required String label,
}) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          style: AppTheme.dialogAction(context),
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text(AppStrings.add),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

Future<bool> _confirmDialog(
  BuildContext context, {
  required String title,
  String? description,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: description == null ? null : Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: AppTheme.dialogAction(context),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    ) ??
    false;

Future<({String type, double reading, String unit, String notes})?>
_meterDialog(BuildContext context) async {
  final formKey = GlobalKey<FormState>();
  final typeController = TextEditingController();
  final readingController = TextEditingController();
  final unitController = TextEditingController();
  final notesController = TextEditingController();
  final result =
      await showDialog<
        ({String type, double reading, String unit, String notes})
      >(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(AppStrings.addMeter),
          content: StatefulBuilder(
            builder: (context, setInnerState) => Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _PresetLabel(),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final preset in _meterPresets)
                          _PresetChip(
                            label: preset.type,
                            selected: typeController.text.trim() == preset.type,
                            onTap: () => setInnerState(() {
                              typeController.text = preset.type;
                              unitController.text = preset.unit;
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: typeController,
                      onChanged: (_) => setInnerState(() {}),
                      decoration: const InputDecoration(
                        labelText: AppStrings.meterType,
                      ),
                      validator: _requiredValue,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: readingController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: AppStrings.meterReading,
                      ),
                      validator: (value) =>
                          double.tryParse(value?.trim() ?? '') == null
                          ? AppStrings.invalidNumber
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: unitController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.meterUnit,
                      ),
                      validator: _requiredValue,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.notes,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(context, (
                  type: typeController.text.trim(),
                  reading: double.parse(readingController.text.trim()),
                  unit: unitController.text.trim(),
                  notes: notesController.text.trim(),
                ));
              },
              child: const Text(AppStrings.add),
            ),
          ],
        ),
      );
  typeController.dispose();
  readingController.dispose();
  unitController.dispose();
  notesController.dispose();
  return result;
}

Future<({String type, int quantity, String notes})?> _keyDialog(
  BuildContext context,
) async {
  final formKey = GlobalKey<FormState>();
  final typeController = TextEditingController();
  final quantityController = TextEditingController();
  final notesController = TextEditingController();
  final result = await showDialog<({String type, int quantity, String notes})>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(AppStrings.addKey),
      content: StatefulBuilder(
        builder: (context, setInnerState) => Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PresetLabel(),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final preset in _keyPresets)
                      _PresetChip(
                        label: preset,
                        selected: typeController.text.trim() == preset,
                        onTap: () =>
                            setInnerState(() => typeController.text = preset),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: typeController,
                  onChanged: (_) => setInnerState(() {}),
                  decoration: const InputDecoration(
                    labelText: AppStrings.keyType,
                  ),
                  validator: _requiredValue,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: AppStrings.keyQuantity,
                  ),
                  validator: (value) =>
                      int.tryParse(value?.trim() ?? '') == null
                      ? AppStrings.invalidNumber
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.notes,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          style: AppTheme.dialogAction(context),
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            Navigator.pop(context, (
              type: typeController.text.trim(),
              quantity: int.parse(quantityController.text.trim()),
              notes: notesController.text.trim(),
            ));
          },
          child: const Text(AppStrings.add),
        ),
      ],
    ),
  );
  typeController.dispose();
  quantityController.dispose();
  notesController.dispose();
  return result;
}

String? _requiredValue(String? value) =>
    value == null || value.trim().isEmpty ? AppStrings.requiredField : null;

// --------------------------------------------------------------- presets ---

const _meterPresets = <({String type, String unit})>[
  (type: AppStrings.meterElectricity, unit: AppStrings.unitKwh),
  (type: AppStrings.meterColdWater, unit: AppStrings.unitCubicMeter),
  (type: AppStrings.meterHotWater, unit: AppStrings.unitCubicMeter),
  (type: AppStrings.meterHeating, unit: AppStrings.unitGcal),
];

const _keyPresets = <String>[
  AppStrings.keyEntrance,
  AppStrings.keyDoor,
  AppStrings.keyMailbox,
  AppStrings.keyCard,
  AppStrings.keyRemote,
];

class _PresetLabel extends StatelessWidget {
  const _PresetLabel();

  @override
  Widget build(BuildContext context) => Text(
    AppStrings.quickPick,
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: context.tokens.textFaint,
    ),
  );
}

/// Тоолуур, түлхүүрийн төрлийг нэг товшилтоор бөглөх чип.
class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? t.brandSoft : t.surfaceMuted,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? t.brand : t.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check_rounded, size: 13, color: t.onBrandSoft),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? t.onBrandSoft : t.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
