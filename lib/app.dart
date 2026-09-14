import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/application/tulkhuur_controller.dart';
import 'core/constants/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/services/backend_service.dart';
import 'core/services/sync_service.dart';
import 'core/theme/app_theme.dart';
import 'features/maintenance/presentation/maintenance_screen.dart';

final connectivityProvider = StreamProvider<List<ConnectivityResult>>(
  (ref) => Connectivity().onConnectivityChanged,
);

class TulkhuurApp extends ConsumerWidget {
  const TulkhuurApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(connectivityProvider, (previous, next) {
      final isOnline = next.value?.any(
        (result) => result != ConnectivityResult.none,
      );
      final backend = ref.read(backendServiceProvider);
      if (isOnline == true &&
          backend.isConfigured &&
          backend.currentUser != null) {
        // Сүлжээ сэргэхэд: эхлээд өгөгдөл, дараа нь зураг.
        ref.read(syncServiceProvider).sync().then((outcome) {
          ref.read(syncStatusProvider.notifier).report(outcome);
          ref.read(tulkhuurControllerProvider.notifier).retryPendingUploads();
        });
      }
    });
    final status = ref.watch(appStatusProvider).value;
    if (status != null && status.maintenance) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppStrings.appName,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        locale: const Locale('mn'),
        supportedLocales: const [Locale('mn')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: MaintenanceScreen(status: status),
      );
    }
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      locale: const Locale('mn'),
      supportedLocales: const [Locale('mn')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
