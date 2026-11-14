/// Una release pública de SemiFund en GitHub.
class AppRelease {
  const AppRelease({
    required this.version,
    required this.name,
    required this.notes,
    required this.downloadUrl,
    required this.pageUrl,
    required this.sizeBytes,
    required this.publishedAt,
  });

  final String version;
  final String name;
  final String notes;
  final String downloadUrl;
  final String pageUrl;
  final int sizeBytes;
  final DateTime? publishedAt;

  String get sizeLabel {
    if (sizeBytes <= 0) return '';
    final double mb = sizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}
