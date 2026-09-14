import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/application/tulkhuur_controller.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/models/app_enums.dart';
import '../../../shared/widgets/app_state_widgets.dart';

class StartInspectionScreen extends ConsumerStatefulWidget {
  const StartInspectionScreen({
    required this.propertyId,
    required this.type,
    super.key,
  });

  final String propertyId;
  final InspectionType type;

  @override
  ConsumerState<StartInspectionScreen> createState() =>
      _StartInspectionScreenState();
}

class _StartInspectionScreenState extends ConsumerState<StartInspectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tenantNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  FillMethod _fillMethod = FillMethod.self;
  bool _saving = false;

  @override
  void dispose() {
    _tenantNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tulkhuurControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(widget.type.label)),
      body: state.when(
        loading: () => const AppLoadingView(),
        error: (error, stack) => AppErrorView(
          error: error,
          onRetry: () => ref.invalidate(tulkhuurControllerProvider),
        ),
        data: (data) {
          final property = data.propertyById(widget.propertyId);
          if (property == null) {
            return const EmptyState(
              icon: Icons.home_work_outlined,
              title: AppStrings.propertyNotFound,
              description: AppStrings.noPropertiesDescription,
            );
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const CircleAvatar(
                      child: Icon(Icons.apartment_rounded),
                    ),
                    title: Text(
                      property.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(property.address),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  AppStrings.chooseFillMethod,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                SegmentedButton<FillMethod>(
                  segments: FillMethod.values
                      .map(
                        (method) => ButtonSegment(
                          value: method,
                          label: Text(method.label),
                          icon: Icon(
                            method == FillMethod.self
                                ? Icons.person_outline_rounded
                                : Icons.forward_to_inbox_outlined,
                          ),
                        ),
                      )
                      .toList(),
                  selected: {_fillMethod},
                  onSelectionChanged: (selection) =>
                      setState(() => _fillMethod = selection.first),
                ),
                if (_fillMethod == FillMethod.tenant) ...[
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.tenantInformation,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _tenantNameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: AppStrings.tenantName,
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: AppStrings.phoneNumber,
                    ),
                    validator: (value) {
                      final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                      return digits.length < 8 ? AppStrings.invalidPhone : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: AppStrings.email,
                      helperText: AppStrings.optional,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      return RegExp(r'^.+@.+\..+$').hasMatch(value.trim())
                          ? null
                          : AppStrings.invalidEmail;
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(AppStrings.secureInvitationNote),
                ],
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _saving ? null : _start,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: const Text(AppStrings.continueLabel),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? AppStrings.requiredField : null;

  Future<void> _start() async {
    if (_fillMethod == FillMethod.tenant &&
        !_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      final inspection = await ref
          .read(tulkhuurControllerProvider.notifier)
          .createInspection(
            propertyId: widget.propertyId,
            type: widget.type,
            fillMethod: _fillMethod,
            tenantName: _tenantNameController.text,
            tenantPhone: _phoneController.text,
            tenantEmail: _emailController.text,
          );
      if (!mounted) return;
      context.pushReplacement('/inspections/${inspection.id}/edit');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_cleanError(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _cleanError(Object error) => error is StateError
      ? error.message.toString()
      : AppStrings.errorWithDetails(error);
}
