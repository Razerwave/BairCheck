import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';

/// Доод навигаци — голдоо хөвөгч нэмэх товчтой.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  static const _barHeight = 64.0;
  static const _fabOverhang = 20.0;

  final StatefulNavigationShell navigationShell;

  void _go(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SizedBox(
        height: _barHeight + _fabOverhang + safeBottom,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _barHeight + safeBottom,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: t.navBackground,
                  border: Border(top: BorderSide(color: t.navBorder)),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(bottom: safeBottom),
                child: Row(
                  children: [
                    _NavItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: AppStrings.home,
                      selected: navigationShell.currentIndex == 0,
                      onTap: () => _go(0),
                    ),
                    _NavItem(
                      icon: Icons.fact_check_outlined,
                      activeIcon: Icons.fact_check_rounded,
                      label: AppStrings.inspections,
                      selected: navigationShell.currentIndex == 1,
                      onTap: () => _go(1),
                    ),
                    _AddButton(onTap: () => _go(2)),
                    _NavItem(
                      icon: Icons.description_outlined,
                      activeIcon: Icons.description_rounded,
                      label: AppStrings.navActs,
                      selected: navigationShell.currentIndex == 3,
                      onTap: () => _go(3),
                    ),
                    _NavItem(
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: AppStrings.profile,
                      selected: navigationShell.currentIndex == 4,
                      onTap: () => _go(4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = selected ? t.textPrimary : t.textFaint;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(selected ? activeIcon : icon, size: 21, color: color),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.1,
                      letterSpacing: -0.1,
                      color: color,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Expanded(
      child: Semantics(
        button: true,
        label: AppStrings.add,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: t.navBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                          colors: t.fabGradient,
                        ),
                        boxShadow: t.fabShadow,
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppStrings.add,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      color: t.brandStrong,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
