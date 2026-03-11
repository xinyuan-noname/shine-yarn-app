class AppConfig {
  static const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);

  static String get assetUrl {
    return isProduction
        ? "https://gitee.com/xinyuanwm/asset/raw/production/url.txt"
        : "https://gitee.com/xinyuanwm/asset/raw/main/url.txt";
  }
}