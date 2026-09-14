import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/backend_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_back_button.dart';

/// Гүйцэтгэгдээгүй урилгын токен. Нэвтрэх урсгалын дараа ашиглана.
class PendingInviteToken extends Notifier<String?> {
  @override
  String? build() => null;

  void remember(String? token) => state = token;
}

final pendingInviteTokenProvider =
    NotifierProvider<PendingInviteToken, String?>(PendingInviteToken.new);

/// `https://tulkhuur.mn/invite/<token>` холбоосоор нээгддэг дэлгэц.
class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({required this.token, super.key});

  final String token;

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  @override
  void initState() {
    super.initState();
    // Токеныг хадгална — нэвтэрсний дараа боловсруулна.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pendingInviteTokenProvider.notifier).remember(widget.token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final signedIn = ref.watch(backendServiceProvider).currentUser != null;
    final shortToken = widget.token.length > 8
        ? '${widget.token.substring(0, 8)}…'
        : widget.token;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: '/'),
        title: const Text(AppStrings.invitationTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: t.brandSoft,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: t.brandSoftBorder),
              ),
              child: Icon(Icons.mark_email_read_outlined, size: 46, color: t.brand),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            AppStrings.invitationReceived,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.invitationDescription,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: t.textMuted),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: t.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.border),
            ),
            child: Row(
              children: [
                Icon(Icons.key_outlined, size: 18, color: t.textMuted),
                const SizedBox(width: 10),
                Text(
                  AppStrings.invitationCode,
                  style: TextStyle(fontSize: 12, color: t.textMuted),
                ),
                const Spacer(),
                Text(
                  shortToken,
                  style: TextStyle(
                    fontFamily: AppTheme.displayFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          if (!signedIn)
            FilledButton.icon(
              onPressed: () => context.push('/auth'),
              icon: const Icon(Icons.login_rounded),
              label: const Text(AppStrings.signIn),
            ),
          const SizedBox(height: 12),
          Text(
            AppStrings.invitationPendingServer,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: t.textFaint),
          ),
        ],
      ),
    );
  }
}
