import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/application/tulkhuur_controller.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/app_state_widgets.dart';

class AddHubScreen extends ConsumerWidget {
  const AddHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tulkhuurControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.add)),
      body: state.when(
        loading: () => const AppLoadingView(),
        error: (error, stack) => AppErrorView(
          error: error,
          onRetry: () => ref.invalidate(tulkhuurControllerProvider),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ActionCard(
              icon: Icons.add_home_work_rounded,
              title: AppStrings.addProperty,
              description: AppStrings.addNewPropertyDescription,
              onTap: () => context.push('/properties/new'),
            ),
            const SizedBox(height: 14),
            _ActionCard(
              icon: Icons.fact_check_outlined,
              title: AppStrings.startInspection,
              description: AppStrings.startInspectionDescription,
              onTap: data.properties.isEmpty
                  ? () => context.push('/properties/new')
                  : () => _chooseProperty(context, data.properties),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseProperty(BuildContext context, List properties) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.chooseProperty,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ...properties.map(
                (property) => ListTile(
                  leading: const Icon(Icons.apartment_rounded),
                  title: Text(property.name as String),
                  subtitle: Text(property.address as String),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push('/properties/${property.id}');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(radius: 28, child: Icon(icon, size: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(description),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}
