import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/app_status.dart';
import '../config/app_config.dart';

class BackendService {
  const BackendService._({required this.isConfigured, this.client});

  final bool isConfigured;
  final SupabaseClient? client;

  static Future<BackendService> initialize(AppConfig config) async {
    if (!config.hasSupabase) {
      return const BackendService._(isConfigured: false);
    }
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabasePublishableKey,
    );
    return BackendService._(
      isConfigured: true,
      client: Supabase.instance.client,
    );
  }

  User? get currentUser => client?.auth.currentUser;

  /// Нэвтрэх, гарах зэрэг өөрчлөлтийг дагана.
  Stream<AuthState> get authChanges =>
      client?.auth.onAuthStateChange ?? const Stream.empty();

  /// Серверийн төлөвийг уншина. Холболт байхгүй, удаан эсвэл алдаатай бол
  /// `null` буцаана — апп хаагдахгүй (fail-open).
  Future<AppStatus?> fetchAppStatus() async {
    final supabase = client;
    if (supabase == null) return null;
    try {
      final row = await supabase
          .from('app_status')
          .select()
          .limit(1)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));
      if (row == null) return null;
      return AppStatus.fromJson(row);
    } catch (_) {
      return null;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final supabase = client;
    if (supabase == null) throw StateError('Supabase is not configured.');
    await supabase.auth.signInWithPassword(email: email, password: password);
    await ensureProfile();
  }

  Future<void> signOut() async => client?.auth.signOut();

  /// Шинэ бүртгэл үүсгэнэ. И-мэйл баталгаажуулалт асаалттай үед session
  /// шууд үүсэхгүй тул профайлыг дараагийн нэвтрэлтэд үүсгэнэ.
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final supabase = client;
    if (supabase == null) throw StateError('Supabase is not configured.');
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    if (response.session != null) {
      await ensureProfile(fullName: fullName);
      return true;
    }
    return false;
  }

  /// `public.profiles` дээр мөр байгаа эсэхийг баталгаажуулна.
  Future<void> ensureProfile({String? fullName}) async {
    final supabase = client;
    final user = currentUser;
    if (supabase == null || user == null) return;
    final name =
        fullName?.trim().isNotEmpty == true
        ? fullName!.trim()
        : (user.userMetadata?['full_name'] as String?)?.trim().isNotEmpty == true
        ? (user.userMetadata!['full_name'] as String).trim()
        : (user.email?.split('@').first ?? 'Түлхүүр');
    try {
      await supabase.from('profiles').upsert({
        'id': user.id,
        'full_name': name,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // Профайл үүсгэж чадаагүй нь нэвтрэлтийг тасалдуулах шалтгаан биш.
    }
  }

  /// Бүртгэлийг бүрмөсөн устгана (сервер талын edge function гүйцэтгэнэ).
  Future<void> deleteAccount() async {
    final supabase = client;
    if (supabase == null || currentUser == null) {
      throw StateError('Authenticated Supabase client is required.');
    }
    final response = await supabase.functions.invoke('delete-account');
    if (response.status != 200) {
      throw Exception('delete-account failed: ${response.status}');
    }
    await supabase.auth.signOut();
  }

  Future<String> uploadInspectionPhoto({
    required String inspectionId,
    required String itemId,
    required String photoId,
    required String localPath,
  }) async {
    final supabase = client;
    final user = currentUser;
    if (supabase == null || user == null) {
      throw StateError('Authenticated Supabase client is required.');
    }
    final remotePath = '${user.id}/$inspectionId/$itemId/$photoId.jpg';
    await supabase.storage
        .from('inspection-evidence')
        .upload(
          remotePath,
          File(localPath),
          fileOptions: const FileOptions(cacheControl: '3600'),
        );
    return remotePath;
  }

  Future<void> sendFeedback({
    required String category,
    required String description,
    String? attachmentPath,
  }) async {
    final supabase = client;
    final user = currentUser;
    if (supabase == null || user == null) {
      throw StateError('Authenticated Supabase client is required.');
    }

    String? remoteAttachmentPath;
    if (attachmentPath != null) {
      remoteAttachmentPath =
          '${user.id}/${DateTime.now().microsecondsSinceEpoch}.jpg';
      await supabase.storage
          .from('feedback-attachments')
          .upload(remoteAttachmentPath, File(attachmentPath));
    }
    await supabase.from('feedback').insert({
      'user_id': user.id,
      'category': category,
      'description': description,
      'attachment_path': remoteAttachmentPath,
    });
  }
}

final backendServiceProvider = Provider<BackendService>(
  (ref) => throw UnimplementedError(),
);

/// Нэвтрэлтийн төлөв өөрчлөгдөхөд дэлгэцүүд дахин зурагдана.
final authChangesProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(backendServiceProvider).authChanges,
);
