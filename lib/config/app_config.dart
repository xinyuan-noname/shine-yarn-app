class AppConfig {
  // flutter run --dart-define=PRODUCTION=true
  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );
  static String get serverUrl {
    return isProduction
        ? "https://gitee.com/xinyuanwm/asset/raw/prod/url.txt"
        : "https://gitee.com/xinyuanwm/asset/raw/main/url.txt";
  }

  static String get appInfoUrl {
    return isProduction
        ? "https://gitee.com/xinyuanwm/asset/raw/prod/version.json"
        : "https://gitee.com/xinyuanwm/asset/raw/main/version.json";
  }
}
