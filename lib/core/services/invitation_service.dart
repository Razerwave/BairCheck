import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'backend_service.dart';

/// Түрээслэгчид үзлэг бөглүүлэх урилга үүсгэх, хүлээн авах үйлчилгээ.
///
/// Токен нь зөвхөн холбоос дотор явна; санд түүний SHA-256 хэш хадгалагдана.
/// Ингэснээр өгөгдлийн сан задарсан ч урилгын холбоосыг сэргээх боломжгүй.
class InvitationService {
  InvitationService(this._backend);

  final BackendService _backend;

  /// Deep link суваг — AndroidManifest болон assetlinks.json-той тааруулна.
  static const baseUrl = 'https://tulkhuur.netlify.app/invite';
  static const validFor = Duration(days: 7);

  bool get canInvite =>
      _backend.client != null && _backend.currentUser != null;

  static String _newToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static String hashToken(String token) =>
      sha256.convert(utf8.encode(token)).toString();

  /// Урилга үүсгээд хуваалцах холбоосыг буцаана.
  Future<String> createInvitation({
    required String inspectionId,
    required String tenantName,
    required String phone,
    String? email,
  }) async {
    final client = _backend.client;
    final user = _backend.currentUser;
    if (client == null || user == null) {
      throw StateError('Authenticated Supabase client is required.');
    }
    final token = _newToken();
    await client.from('inspection_invitations').insert({
      'inspection_id': inspectionId,
      'invited_by': user.id,
      'tenant_name': tenantName,
      'phone': phone,
      'email': email?.trim().isEmpty ?? true ? null : email!.trim(),
      'token_hash': hashToken(token),
      'expires_at': DateTime.now().toUtc().add(validFor).toIso8601String(),
    });
    return '$baseUrl/$token';
  }

  /// Урилгыг хүлээн авна — сервер талд эрх олгогдоно.
  Future<String> acceptInvitation(String token) async {
    final client = _backend.client;
    if (client == null || _backend.currentUser == null) {
      throw StateError('Authenticated Supabase client is required.');
    }
    final response = await client.functions.invoke(
      'accept-invitation',
      body: {'token': token},
    );
    if (response.status != 200) {
      final data = response.data;
      throw Exception(
        data is Map && data['error'] != null
            ? data['error'].toString()
            : 'accept-invitation failed: ${response.status}',
      );
    }
    final data = response.data;
    return data is Map && data['inspection_id'] != null
        ? data['inspection_id'].toString()
        : '';
  }
}

final invitationServiceProvider = Provider<InvitationService>(
  (ref) => InvitationService(ref.watch(backendServiceProvider)),
);
