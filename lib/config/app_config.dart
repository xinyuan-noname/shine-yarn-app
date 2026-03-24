class AppConfig {
  // flutter run --dart-define=PRODUCTION=true
  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );
  static String get serverUrl {
    return isProduction
        ? "https://raw.githubusercontent.com/xinyuan-noname/git-github.com-xinyuan-noname-asset/prod/url.txt"
        : "https://raw.githubusercontent.com/xinyuan-noname/git-github.com-xinyuan-noname-asset/main/url.txt";
  }

}
