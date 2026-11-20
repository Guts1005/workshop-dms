class BackendConfig {
  const BackendConfig({required this.url, required this.publishableKey});

  final String url;
  final String publishableKey;

  bool get isConfigured =>
      url.startsWith('https://') &&
      !url.contains('your-project') &&
      publishableKey.isNotEmpty &&
      !publishableKey.contains('replace-with');

  static const current = BackendConfig(
    url: String.fromEnvironment('SUPABASE_URL'),
    publishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );
}
