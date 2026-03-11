class AppConfig {
  // flutter run --dart-define=PRODUCTION=true
  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );
  static String get assetUrl {
    return isProduction
        ? "https://gitee.com/xinyuanwm/asset/raw/prod/url.txt"
        : "https://gitee.com/xinyuanwm/asset/raw/main/url.txt";
  }
}
