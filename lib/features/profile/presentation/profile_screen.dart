import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/application/tulkhuur_controller.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/backend_service.dart';
import '../../../shared/widgets/app_state_widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final backend = ref.watch(backendServiceProvider);
    final data = ref.watch(tulkhuurControllerProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profile)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BackendNotice(configured: backend.isConfigured),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const CircleAvatar(
                radius: 28,
                child: Icon(Icons.person_outline_rounded, size: 30),
              ),
              title: Text(
                backend.currentUser?.email ?? AppStrings.account,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                backend.currentUser == null
                    ? AppStrings.signIn
                    : AppStrings.currentAccount,
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/auth'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.storage_outlined),
                  title: const Text(AppStrings.localData),
                  subtitle: Text(
                    '${AppStrings.inspectionCount(data?.inspections.length ?? 0)} • '
                    '${data?.properties.length ?? 0} ${AppStrings.propertyUnit}',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.feedback_outlined),
                  title: const Text(AppStrings.feedback),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/feedback'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text(AppStrings.privacyPolicy),
                  subtitle: const Text(AppStrings.confirmationNotice),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/privacy'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline_rounded),
              title: Text(AppStrings.about),
              subtitle: Text(AppStrings.version),
            ),
          ),
          if (backend.currentUser != null) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: _deleting
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.delete_forever_outlined,
                        color: Theme.of(context).colorScheme.error,
                      ),
                title: Text(
                  AppStrings.deleteAccount,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(AppStrings.deleteAccountDescription),
                onTap: _deleting ? null : _confirmDelete,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteAccountQuestion),
        content: const Text(AppStrings.deleteAccountDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              minimumSize: const Size(120, 44),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await ref.read(backendServiceProvider).deleteAccount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.deleteAccountDone)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.deleteAccountFailed)),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }
}
