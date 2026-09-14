import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Дизайн токенууд. Light/dark хоёр багцыг `Theme.of(context).extension` -ээр
/// биш, `context.tokens` товчлолоор уншина.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textMuted,
    required this.textFaint,
    required this.brand,
    required this.brandStrong,
    required this.brandSoft,
    required this.brandSoftBorder,
    required this.onBrandSoft,
    required this.emerald,
    required this.emeraldSoft,
    required this.emeraldBorder,
    required this.onEmeraldSoft,
    required this.amber,
    required this.amberSoft,
    required this.amberBorder,
    required this.onAmberSoft,
    required this.sky,
    required this.skySoft,
    required this.onSkySoft,
    required this.rose,
    required this.inverseSurface,
    required this.onInverseSurface,
    required this.iconTile,
    required this.onIconTile,
    required this.navBackground,
    required this.navBorder,
    required this.fabGradient,
    required this.statTileGradient,
    required this.cardShadow,
    required this.subtleShadow,
    required this.fabShadow,
  });

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color borderStrong;

  final Color textPrimary;
  final Color textMuted;
  final Color textFaint;

  final Color brand;
  final Color brandStrong;
  final Color brandSoft;
  final Color brandSoftBorder;
  final Color onBrandSoft;

  final Color emerald;
  final Color emeraldSoft;
  final Color emeraldBorder;
  final Color onEmeraldSoft;

  final Color amber;
  final Color amberSoft;
  final Color amberBorder;
  final Color onAmberSoft;

  final Color sky;
  final Color skySoft;
  final Color onSkySoft;

  final Color rose;

  /// Эсрэг өнгөт гадаргуу (snackbar гэх мэт).
  final Color inverseSurface;
  final Color onInverseSurface;

  /// Icon дөрвөлжингийн брэнд дүүргэлт (аватар, шуурхай үйлдэл, байрны badge).
  final Color iconTile;
  final Color onIconTile;

  final Color navBackground;
  final Color navBorder;
  final List<Color> fabGradient;

  /// Үндсэн үзүүлэлтийн хавтангийн дүүргэлт (цагаан текст уншигдахуйц гүн teal).
  final List<Color> statTileGradient;

  final List<BoxShadow> cardShadow;
  final List<BoxShadow> subtleShadow;
  final List<BoxShadow> fabShadow;

  static const light = AppTokens(
    background: Color(0xFFF8FAFC),
    surface: Colors.white,
    surfaceMuted: Color(0xFFF1F5F9),
    border: Color(0xFFE7ECF2),
    borderStrong: Color(0xFFCBD5E1),
    textPrimary: Color(0xFF0F172A),
    textMuted: Color(0xFF64748B),
    textFaint: Color(0xFF94A3B8),
    brand: Color(0xFF0D9488),
    brandStrong: Color(0xFF0F766E),
    brandSoft: Color(0xFFF0FDFA),
    brandSoftBorder: Color(0xFFCCFBF1),
    onBrandSoft: Color(0xFF0F766E),
    emerald: Color(0xFF10B981),
    emeraldSoft: Color(0xFFECFDF5),
    emeraldBorder: Color(0xFFBBF7D0),
    onEmeraldSoft: Color(0xFF047857),
    amber: Color(0xFFF59E0B),
    amberSoft: Color(0xFFFFFBEB),
    amberBorder: Color(0xFFFDE68A),
    onAmberSoft: Color(0xFFB45309),
    sky: Color(0xFF0284C7),
    skySoft: Color(0xFFF0F9FF),
    onSkySoft: Color(0xFF0369A1),
    rose: Color(0xFFF43F5E),
    inverseSurface: Color(0xFF3B4D66),
    onInverseSurface: Colors.white,
    iconTile: Color(0xFF0D9488),
    onIconTile: Colors.white,
    navBackground: Colors.white,
    navBorder: Color(0xFFE2E8F0),
    fabGradient: [Color(0xFF115E59), Color(0xFF0D9488), Color(0xFF14B8A6)],
    statTileGradient: [Color(0xFF134E4A), Color(0xFF0F766E)],
    cardShadow: [
      BoxShadow(
        color: Color(0x0F0F172A),
        blurRadius: 24,
        offset: Offset(0, 4),
        spreadRadius: -2,
      ),
      BoxShadow(
        color: Color(0x080F172A),
        blurRadius: 3,
        offset: Offset(0, 1),
        spreadRadius: -1,
      ),
    ],
    subtleShadow: [
      BoxShadow(color: Color(0x0A0F172A), blurRadius: 3, offset: Offset(0, 1)),
    ],
    fabShadow: [
      BoxShadow(
        color: Color(0x6B0D9488),
        blurRadius: 28,
        offset: Offset(0, 12),
        spreadRadius: -6,
      ),
      BoxShadow(
        color: Color(0x400D9488),
        blurRadius: 10,
        offset: Offset(0, 4),
        spreadRadius: -2,
      ),
    ],
  );

  static const dark = AppTokens(
    background: Color(0xFF0B1220),
    surface: Color(0xFF16202F),
    surfaceMuted: Color(0xFF1E293B),
    border: Color(0xFF26364D),
    borderStrong: Color(0xFF3A4B63),
    textPrimary: Color(0xFFF1F5F9),
    textMuted: Color(0xFF94A3B8),
    textFaint: Color(0xFF64748B),
    brand: Color(0xFF2DD4BF),
    brandStrong: Color(0xFF5EEAD4),
    brandSoft: Color(0x2314B8A6),
    brandSoftBorder: Color(0x4D2DD4BF),
    onBrandSoft: Color(0xFF5EEAD4),
    emerald: Color(0xFF34D399),
    emeraldSoft: Color(0x2310B981),
    emeraldBorder: Color(0x4D34D399),
    onEmeraldSoft: Color(0xFF6EE7B7),
    amber: Color(0xFFFBBF24),
    amberSoft: Color(0x26F59E0B),
    amberBorder: Color(0x4DFBBF24),
    onAmberSoft: Color(0xFFFCD34D),
    sky: Color(0xFF38BDF8),
    skySoft: Color(0x260EA5E9),
    onSkySoft: Color(0xFF7DD3FC),
    rose: Color(0xFFFB7185),
    inverseSurface: Color(0xFFC7D2E0),
    onInverseSurface: Color(0xFF16202F),
    iconTile: Color(0xFF0F766E),
    onIconTile: Colors.white,
    navBackground: Color(0xFF111B2B),
    navBorder: Color(0xFF26364D),
    fabGradient: [Color(0xFF0D9488), Color(0xFF14B8A6), Color(0xFF2DD4BF)],
    statTileGradient: [Color(0xFF115E59), Color(0xFF0F766E)],
    cardShadow: [
      BoxShadow(
        color: Color(0x59000000),
        blurRadius: 24,
        offset: Offset(0, 4),
        spreadRadius: -4,
      ),
    ],
    subtleShadow: [
      BoxShadow(color: Color(0x40000000), blurRadius: 3, offset: Offset(0, 1)),
    ],
    fabShadow: [
      BoxShadow(
        color: Color(0x8014B8A6),
        blurRadius: 28,
        offset: Offset(0, 12),
        spreadRadius: -8,
      ),
    ],
  );

  @override
  AppTokens copyWith() => this;

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) =>
      other is AppTokens && t >= 0.5 ? other : this;
}

extension AppTokensContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>() ?? AppTokens.light;
}

abstract final class AppTheme {
  /// Диалогийн үйлдлийн товч. Ерөнхий FilledButton нь маягтад зориулж бүтэн
  /// өргөнтэй байдаг тул диалогт нягт хувилбарыг нь ашиглана.
  static ButtonStyle dialogAction(BuildContext context) =>
      FilledButton.styleFrom(
        minimumSize: const Size(92, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      );

  /// Латин бичиг, тоонд зориулсан дэлгэцийн фонт (кирилл дэмждэггүй тул
  /// зөвхөн брэнд болон тоон утгад хэрэглэнэ).
  static const displayFont = 'PlusJakartaSans';

  static ThemeData get light => _build(AppTokens.light, Brightness.light);
  static ThemeData get dark => _build(AppTokens.dark, Brightness.dark);

  static ThemeData _build(AppTokens t, Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: t.brand,
      onPrimary: isLight ? Colors.white : const Color(0xFF042F2E),
      primaryContainer: t.brandSoft,
      onPrimaryContainer: t.onBrandSoft,
      secondary: t.emerald,
      onSecondary: isLight ? Colors.white : const Color(0xFF022C22),
      secondaryContainer: t.emeraldSoft,
      onSecondaryContainer: t.onEmeraldSoft,
      error: isLight ? const Color(0xFFE11D48) : const Color(0xFFFB7185),
      onError: isLight ? Colors.white : const Color(0xFF4C0519),
      surface: t.surface,
      onSurface: t.textPrimary,
      surfaceContainerHighest: t.surfaceMuted,
      onSurfaceVariant: t.textMuted,
      outline: t.border,
      outlineVariant: t.border,
      shadow: const Color(0xFF0F172A),
    );

    final text = _textTheme(t);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: t.background,
      canvasColor: t.background,
      fontFamily: 'Inter',
      fontFamilyFallback: const ['NotoSans'],
      textTheme: text,
      extensions: [t],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: t.surface,
        foregroundColor: t.textPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 60,
        titleSpacing: 20,
        shape: Border(bottom: BorderSide(color: t.border)),
        titleTextStyle: text.titleLarge?.copyWith(fontSize: 17),
        iconTheme: IconThemeData(color: t.textPrimary, size: 22),
        actionsIconTheme: IconThemeData(color: t.textPrimary, size: 22),
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
              )
            : SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
              ),
      ),
      cardTheme: CardThemeData(
        color: t.surface,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: t.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: t.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: t.onInverseSurface,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surface,
        hintStyle: text.bodyMedium?.copyWith(color: t.textFaint),
        labelStyle: text.bodyMedium?.copyWith(color: t.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.brand, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: t.brand,
          foregroundColor: isLight ? Colors.white : const Color(0xFF042F2E),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.textPrimary,
          side: BorderSide(color: t.border),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.brandStrong,
          textStyle: text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: t.surfaceMuted,
        labelStyle: text.labelSmall?.copyWith(color: t.textMuted),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: t.textMuted,
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodyMedium?.copyWith(color: t.textMuted),
      ),
      dividerTheme: DividerThemeData(color: t.border, space: 1, thickness: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: t.brand),
      iconTheme: IconThemeData(color: t.textMuted),
    );
  }

  static TextTheme _textTheme(AppTokens t) => TextTheme(
    headlineMedium: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
      color: t.textPrimary,
    ),
    headlineSmall: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.6,
      height: 1.2,
      color: t.textPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: t.textPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: t.textPrimary,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.1,
      color: t.textPrimary,
    ),
    bodyLarge: TextStyle(fontSize: 14, height: 1.45, color: t.textPrimary),
    bodyMedium: TextStyle(fontSize: 12.5, height: 1.45, color: t.textMuted),
    bodySmall: TextStyle(fontSize: 11, height: 1.4, color: t.textFaint),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: t.textPrimary,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: t.textMuted,
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: t.textMuted,
    ),
  );
}
