import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/application/tulkhuur_controller.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/models/app_enums.dart';
import '../../../shared/widgets/app_state_widgets.dart';
import '../../../shared/widgets/status_chip.dart';

class InspectionsScreen extends ConsumerWidget {
  const InspectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tulkhuurControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.inspections)),
      body: state.when(
        loading: () => const AppLoadingView(),
        error: (error, stack) => AppErrorView(
          error: error,
          onRetry: () => ref.invalidate(tulkhuurControllerProvider),
        ),
        data: (data) {
          if (data.inspections.isEmpty) {
            return EmptyState(
              icon: Icons.fact_check_outlined,
              title: AppStrings.noInspections,
              description: AppStrings.noInspectionsDescription,
              actionLabel: AppStrings.add,
              onAction: () => context.go('/add'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: data.inspections.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final inspection = data.inspections[index];
              final property = data.propertyById(inspection.propertyId);
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => context.push('/inspections/${inspection.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          child: Icon(
                            inspection.type == InspectionType.moveIn
                                ? Icons.login_rounded
                                : Icons.logout_rounded,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                property?.name ?? AppStrings.propertyNotFound,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(inspection.type.label),
                              const SizedBox(height: 8),
                              InspectionStatusChip(status: inspection.status),
                              const SizedBox(height: 5),
                              Text(
                                AppStrings.updatedAt(
                                  DateFormat('yyyy.MM.dd HH:mm')
                                      .format(inspection.updatedAt),
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
