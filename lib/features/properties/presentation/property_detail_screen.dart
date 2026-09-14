import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/application/tulkhuur_controller.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/app_enums.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_state_widgets.dart';
import '../../../shared/widgets/status_chip.dart';

class PropertyDetailScreen extends ConsumerWidget {
  const PropertyDetailScreen({required this.propertyId, super.key});

  final String propertyId;

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
        final property = data.propertyById(propertyId);
        if (property == null) {
          return const Scaffold(
            body: EmptyState(
              icon: Icons.home_work_outlined,
              title: AppStrings.propertyNotFound,
              description: AppStrings.noPropertiesDescription,
            ),
          );
        }
        final inspections = data.inspectionsForProperty(propertyId);
        return Scaffold(
          appBar: AppBar(
            leading: const AppBackButton(fallbackLocation: '/'),
            title: Text(property.name),
            actions: [
              IconButton(
                onPressed: () => context.push('/properties/$propertyId/edit'),
                tooltip: AppStrings.edit,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.propertyInformation,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 14),
                      _InfoRow(
                        icon: Icons.place_outlined,
                        value: property.address,
                      ),
                      _InfoRow(
                        icon: Icons.chair_outlined,
                        value: property.furnishingType.label,
                      ),
                      _InfoRow(
                        icon: Icons.square_foot_rounded,
                        value:
                            '${property.areaSquareMeters.toStringAsFixed(0)} ${AppStrings.areaUnit}',
                      ),
                      _InfoRow(
                        icon: Icons.stairs_outlined,
                        value: '${property.floor} ${AppStrings.floor}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => context.push(
                  '/properties/$propertyId/start/${InspectionType.moveIn.databaseValue}',
                ),
                icon: const Icon(Icons.login_rounded),
                label: const Text(AppStrings.startMoveIn),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => context.push(
                  '/properties/$propertyId/start/${InspectionType.moveOut.databaseValue}',
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text(AppStrings.startMoveOut),
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.inspections,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              if (inspections.isEmpty)
                const Card(
                  child: EmptyState(
                    icon: Icons.fact_check_outlined,
                    title: AppStrings.noInspections,
                    description: AppStrings.noInspectionsDescription,
                  ),
                )
              else
                ...inspections.map(
                  (inspection) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        leading: Icon(
                          inspection.type == InspectionType.moveIn
                              ? Icons.login_rounded
                              : Icons.logout_rounded,
                        ),
                        title: Text(
                          inspection.type.label,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: InspectionStatusChip(
                          status: inspection.status,
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () =>
                            context.push('/inspections/${inspection.id}'),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(icon, size: 20, color: context.tokens.textMuted),
        const SizedBox(width: 10),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
