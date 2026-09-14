import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';

/// Буцах товч. `context.go` -оор орж ирсэн дэлгэц дээр pop хийх зүйл байхгүй
/// (стек солигдсон) тул тэр тохиолдолд `fallbackLocation` руу шилжинэ.
class AppBackButton extends StatelessWidget {
  const AppBackButton({required this.fallbackLocation, super.key});

  final String fallbackLocation;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: AppStrings.back,
    icon: const Icon(Icons.arrow_back_rounded),
    onPressed: () {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(fallbackLocation);
      }
    },
  );
}
