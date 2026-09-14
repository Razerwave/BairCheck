import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/services/backend_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  final backend = await BackendService.initialize(config);
  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        backendServiceProvider.overrideWithValue(backend),
      ],
      child: const TulkhuurApp(),
    ),
  );
}
