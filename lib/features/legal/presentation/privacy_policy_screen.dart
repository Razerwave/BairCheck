import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';

/// Аппын нууцлалын бодлого. Store-ын шаардлагын дагуу апп дотроос
/// нэвтрэхгүйгээр хүртэл уншиж болно.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = <(String, String)>[
    (
      'Бид ямар мэдээлэл цуглуулдаг вэ?',
      'И-мэйл хаяг болон нэр (бүртгэл үүсгэхэд), таны оруулсан байрны '
          'мэдээлэл, үзлэгийн бичилт, тоолуурын заалт, түлхүүрийн бүртгэл, '
          'мөн үзлэгийн явцад авсан зураг.',
    ),
    (
      'Яагаад цуглуулдаг вэ?',
      'Зөвхөн үзлэг хийх, хүлээлцэх акт үүсгэх, оролцогч талуудад хуваалцах '
          'зорилгоор. Бид таны мэдээллийг зар сурталчилгаанд ашиглахгүй, '
          'гуравдагч талд зардаггүй.',
    ),
    (
      'Мэдээлэл хаана хадгалагддаг вэ?',
      'Ноорог мэдээлэл таны төхөөрөмж дээр хадгалагдана. Нэвтэрсэн үед '
          'мэдээлэл Supabase (PostgreSQL) дээр шифрлэгдсэн холболтоор '
          'дамжин хадгалагдана. Мөр бүр эзэмшигчийн эрхээр хамгаалагдсан.',
    ),
    (
      'Хэн харах боломжтой вэ?',
      'Зөвхөн та болон тухайн байр, үзлэгт оролцогчоор бүртгэгдсэн хүмүүс.',
    ),
    (
      'Хэр удаан хадгалах вэ?',
      'Та бүртгэлээ устгах хүртэл. Бүртгэлээ устгахад сервер дээрх таны '
          'бүх байр, үзлэг, зураг бүрмөсөн устна.',
    ),
    (
      'Таны эрх',
      'Профайл хэсгээс бүртгэлээ хэдийд ч устгах боломжтой. Мэдээллээ '
          'хуулбарлан авах эсвэл засах хүсэлтээ санал хүсэлтийн хэсгээр '
          'дамжуулан илгээж болно.',
    ),
    (
      'Камер ба зургийн сан',
      'Камер болон зургийн санд зөвхөн үзлэгийн нотлох зураг оруулах үед '
          'хандана. Бусад зургийг тань уншихгүй.',
    ),
    (
      'Хууль зүйн статус',
      'Аппаар үүсгэсэн баталгаажуулалт нь талуудын зөвшөөрлийн бичилт '
          'бөгөөд цахим гарын үсгийн тухай хуулийн дагуух цахим гарын үсэг '
          'биш болно.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.privacyPolicy)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            AppStrings.appName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.privacyUpdated,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: t.textFaint),
          ),
          const SizedBox(height: 20),
          for (final (title, body) in _sections) ...[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              body,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: t.textMuted),
            ),
            const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}
