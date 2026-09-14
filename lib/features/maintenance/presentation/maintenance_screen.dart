import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/backend_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/app_status.dart';

/// Серверийн төлөвийг уншина. Алдаа гарвал ажиллагаатай гэж үзнэ.
final appStatusProvider = FutureProvider<AppStatus>((ref) async {
  final backend = ref.watch(backendServiceProvider);
  final status = await backend.fetchAppStatus();
  return status ?? const AppStatus.available();
});

/// Засвар үйлчилгээний үед бүтэн дэлгэцээр харагдана.
class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({required this.status, super.key});

  final AppStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: t.brandSoft,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: t.brandSoftBorder),
                  ),
                  child: Icon(
                    Icons.build_circle_outlined,
                    size: 52,
                    color: t.brand,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  status.title.isEmpty
                      ? AppStrings.maintenanceTitle
                      : status.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  status.message.isEmpty
                      ? AppStrings.maintenanceDescription
                      : status.message,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: t.textMuted),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 220,
                  child: FilledButton.icon(
                    onPressed: () => ref.invalidate(appStatusProvider),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text(AppStrings.retry),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.maintenanceLocalNotice,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: t.textFaint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
