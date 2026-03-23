class AppConfig {
  // flutter run --dart-define=PRODUCTION=true
  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );
  static String get serverUrl {
    return isProduction
        ? "https://shine-yarn-url-prod.netlify.app/url.txt"
        : "https://shine-yarn-url.netlify.app/url.txt";
  }

}
