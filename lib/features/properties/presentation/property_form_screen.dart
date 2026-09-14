import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/application/tulkhuur_controller.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/models/app_enums.dart';

class PropertyFormScreen extends ConsumerStatefulWidget {
  const PropertyFormScreen({this.propertyId, super.key});

  final String? propertyId;

  @override
  ConsumerState<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends ConsumerState<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _floorController = TextEditingController();
  FurnishingType _furnishingType = FurnishingType.unfurnished;
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _floorController.dispose();
    super.dispose();
  }

  void _initialize() {
    if (_initialized || widget.propertyId == null) return;
    final property = ref
        .read(tulkhuurControllerProvider)
        .value
        ?.propertyById(widget.propertyId!);
    if (property == null) return;
    _nameController.text = property.name;
    _addressController.text = property.address;
    _areaController.text = property.areaSquareMeters.toStringAsFixed(0);
    _floorController.text = property.floor.toString();
    _furnishingType = property.furnishingType;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    _initialize();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.propertyId == null
              ? AppStrings.addProperty
              : AppStrings.propertyInformation,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: AppStrings.propertyName,
                hintText: AppStrings.propertyNameHint,
              ),
              validator: _required,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _addressController,
              textInputAction: TextInputAction.next,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: AppStrings.address),
              validator: _required,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<FurnishingType>(
              initialValue: _furnishingType,
              decoration: const InputDecoration(
                labelText: AppStrings.furnishing,
              ),
              items: FurnishingType.values
                  .map(
                    (type) =>
                        DropdownMenuItem(value: type, child: Text(type.label)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _furnishingType = value!),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _areaController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: AppStrings.area,
                      suffixText: AppStrings.areaUnit,
                    ),
                    validator: (value) {
                      final parsed = double.tryParse(value?.trim() ?? '');
                      return parsed == null || parsed <= 0
                          ? AppStrings.emptyArea
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _floorController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: AppStrings.floor,
                    ),
                    validator: (value) =>
                        int.tryParse(value?.trim() ?? '') == null
                        ? AppStrings.emptyFloor
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? AppStrings.requiredField : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final property = await ref
          .read(tulkhuurControllerProvider.notifier)
          .saveProperty(
            id: widget.propertyId,
            name: _nameController.text,
            address: _addressController.text,
            furnishingType: _furnishingType,
            areaSquareMeters: double.parse(_areaController.text.trim()),
            floor: int.parse(_floorController.text.trim()),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.propertySaved)));
      context.pushReplacement('/properties/${property.id}');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.errorWithDetails(error))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
