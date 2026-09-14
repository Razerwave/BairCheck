import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/application/tulkhuur_controller.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/pdf_service.dart';
import '../../../shared/models/app_enums.dart';
import '../../../shared/models/inspection.dart';
import '../../../shared/widgets/app_state_widgets.dart';

class ActsScreen extends ConsumerWidget {
  const ActsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tulkhuurControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.handoverAct)),
      body: state.when(
        loading: () => const AppLoadingView(),
        error: (error, stack) => AppErrorView(
          error: error,
          onRetry: () => ref.invalidate(tulkhuurControllerProvider),
        ),
        data: (data) {
          final finalized = data.inspections
              .where((item) => item.status == InspectionStatus.finalized)
              .toList(growable: false);
          if (finalized.isEmpty) {
            return const EmptyState(
              icon: Icons.description_outlined,
              title: AppStrings.noActs,
              description: AppStrings.noActsDescription,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: finalized.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final inspection = finalized[index];
              final property = data.propertyById(inspection.propertyId);
              return _ActCard(
                inspection: inspection,
                propertyName: property?.name ?? AppStrings.propertyNotFound,
                onOpen: () => context.push('/inspections/${inspection.id}'),
                onPdf: property == null
                    ? null
                    : () async {
                        await ref
                            .read(pdfServiceProvider)
                            .presentHandoverAct(
                              property: property,
                              inspection: inspection,
                            );
                      },
              );
            },
          );
        },
      ),
    );
  }
}

class _ActCard extends StatelessWidget {
  const _ActCard({
    required this.inspection,
    required this.propertyName,
    required this.onOpen,
    required this.onPdf,
  });

  final Inspection inspection;
  final String propertyName;
  final VoidCallback onOpen;
  final Future<void> Function()? onPdf;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(child: Icon(Icons.description_outlined)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      propertyName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(DateFormat('yyyy.MM.dd').format(inspection.updatedAt)),
                  ],
                ),
              ),
              IconButton(
                onPressed: onOpen,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text(AppStrings.createPdf),
          ),
        ],
      ),
    ),
  );
}
