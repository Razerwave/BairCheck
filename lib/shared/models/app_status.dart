/// Серверээс ирэх аппын төлөв — засвар үйлчилгээний горим болон
/// шаардлагатай хамгийн бага хувилбар.
class AppStatus {
  const AppStatus({
    required this.maintenance,
    required this.title,
    required this.message,
    this.minimumVersion,
  });

  const AppStatus.available()
    : maintenance = false,
      title = '',
      message = '',
      minimumVersion = null;

  final bool maintenance;
  final String title;
  final String message;
  final String? minimumVersion;

  factory AppStatus.fromJson(Map<String, Object?> json) => AppStatus(
    maintenance: json['maintenance'] as bool? ?? false,
    title: (json['title'] as String? ?? '').trim(),
    message: (json['message'] as String? ?? '').trim(),
    minimumVersion: (json['minimum_version'] as String?)?.trim(),
  );
}
