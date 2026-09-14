import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/backend_service.dart';
import '../../../core/services/photo_service.dart';
import '../../../shared/models/app_enums.dart';
import '../../../shared/models/inspection.dart';
import '../../../shared/widgets/app_state_widgets.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  FeedbackCategory _category = FeedbackCategory.idea;
  EvidencePhoto? _attachment;
  bool _sending = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backend = ref.watch(backendServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.feedback)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            BackendNotice(configured: backend.isConfigured),
            const SizedBox(height: 16),
            DropdownButtonFormField<FeedbackCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: AppStrings.feedbackCategory,
              ),
              items: FeedbackCategory.values
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _category = value!),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              minLines: 5,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: AppStrings.feedbackDescription,
                hintText: AppStrings.feedbackDescriptionHint,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? AppStrings.requiredField
                  : null,
            ),
            const SizedBox(height: 14),
            if (_attachment != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(_attachment!.localPath),
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: IconButton.filled(
                      onPressed: () => setState(() => _attachment = null),
                      tooltip: AppStrings.removePhoto,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _pickAttachment,
                icon: const Icon(Icons.attach_file_rounded),
                label: const Text(AppStrings.attachImage),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: const Text(AppStrings.send),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAttachment() async {
    try {
      final photo = await ref
          .read(photoServiceProvider)
          .pickAndPreserve(ImageSource.gallery);
      if (photo != null && mounted) setState(() => _attachment = photo);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.photoPermissionError)),
      );
    }
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    final backend = ref.read(backendServiceProvider);
    if (!backend.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.integrationRequired)),
      );
      return;
    }
    if (backend.currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.signInRequired)));
      return;
    }
    setState(() => _sending = true);
    try {
      await backend.sendFeedback(
        category: _category.databaseValue,
        description: _descriptionController.text.trim(),
        attachmentPath: _attachment?.localPath,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.feedbackReceived)),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.errorWithDetails(error))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
