import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shine/config/app_config.dart';

/// 服务端 release.json 里描述的一个发布版本。
///
/// 形如：
/// ```json
/// { "apk": "1.0.1.11.apk", "setup": "1.0.0.exe", "version": "1.0.0",
///   "forceUpdate": false, "info": "我们的APP升级了，请及时更新！" }
/// ```
class AppReleaseInfo {
  /// Android 安装包文件名（相对 asset 仓库根目录）
  final String apk;

  /// Windows 安装包文件名
  final String setup;

  /// release.json 里声明的版本号
  final String version;

  /// 是否强制更新（强制时会进入严格离线模式）
  final bool forceUpdate;

  /// 更新说明
  final String info;

  const AppReleaseInfo({
    this.apk = '',
    this.setup = '',
    this.version = '',
    this.forceUpdate = false,
    this.info = '',
  });

  /// 容错解析：字段缺失或类型不对时退化成空值。
  ///
  /// 之前这里直接 `as String` / `as bool`，release.json 少一个字段就会在
  /// 首页初始化时抛类型异常（而且没人接），检查更新会静默失效。
  static AppReleaseInfo? fromMap(dynamic data) {
    if (data is! Map) return null;
    final apk = _asText(data['apk']);
    final setup = _asText(data['setup']);
    final version = _asText(data['version']);
    if (apk.isEmpty && setup.isEmpty && version.isEmpty) return null;
    return AppReleaseInfo(
      apk: apk,
      setup: setup,
      version: version,
      forceUpdate: data['forceUpdate'] == true || data['forceUpdate'] == 'true',
      info: _asText(data['info']),
    );
  }

  /// 指定平台的安装包文件名
  String assetNameFor({required bool isWindows}) =>
      (isWindows ? setup : apk).trim();

  /// 文件名里带的版本号：「1.0.1.11.apk」→「1.0.1.11」，取不到时为空串
  static String versionOfAsset(String assetName) => _versionInAssetName(assetName);

  /// 该平台对应的远端版本号。
  ///
  /// 优先用 release.json 声明的 version；只有声明缺失、或者安装包文件名
  /// 里的版本更高时才用文件名里的 —— asset 仓库里就出现过「安装了新包但
  /// 忘了改 version」的情况（声明 1.0.0，实际挂的是 1.0.1.11.apk），
  /// 只认声明值会让所有用户都收不到更新提示。
  String versionFor({required bool isWindows}) {
    final declared = version.trim();
    final fromAsset = versionOfAsset(assetNameFor(isWindows: isWindows));
    if (fromAsset.isEmpty) return declared;
    if (declared.isEmpty) return fromAsset;
    return compareVersionStrings(fromAsset, declared) > 0 ? fromAsset : declared;
  }

  /// 指定平台上是否有比 [localVersion] 更新的版本
  bool isNewerThan(String localVersion, {required bool isWindows}) =>
      compareVersionStrings(
        versionFor(isWindows: isWindows),
        localVersion,
      ) >
      0;

  /// 面向用户的更新说明
  String get displayInfo {
    final trimmed = info.trim();
    return trimmed.isEmpty ? '本次更新没有附带说明' : trimmed;
  }

  @override
  String toString() =>
      'AppReleaseInfo(apk: $apk, setup: $setup, version: $version, '
      'forceUpdate: $forceUpdate)';
}

/// 检查更新的结果：要么拿到版本信息，要么拿到失败原因
class AppUpdateCheck {
  final AppReleaseInfo? release;
  final String? error;

  const AppUpdateCheck.success(AppReleaseInfo this.release) : error = null;

  const AppUpdateCheck.failure(String this.error) : release = null;

  bool get ok => release != null;
}

/// 把版本号拆成数字段：「1.0.1+10」→ [1, 0, 1, 10]
///
/// 预发布后缀（`-beta.1`）不参与比较；取不到数字时返回空列表。
List<int> parseVersionParts(String raw) {
  final core = raw.trim().split('-').first;
  return RegExp(r'\d+')
      .allMatches(core)
      .map((match) => int.tryParse(match.group(0)!) ?? 0)
      .toList();
}

/// 文件名里的版本号形状：只认「数字.数字…」，
/// 免得把 `1.0.1.11-64bit.apk` 里的 64 也当成一段版本
final RegExp _assetVersionPattern = RegExp(r'\d+(?:\.\d+)+');

String _versionInAssetName(String assetName) =>
    _assetVersionPattern.firstMatch(assetName.trim())?.group(0) ?? '';

/// 宽松的版本号比较：逐段比数字，段数不同时缺的按 0 算。
///
/// 不能用 `Version.parse` 直接比 —— 它是严格的 semver，像「1.0.1.11」
/// 这种四段版本号会直接抛 FormatException（而 asset 仓库的安装包就是
/// 按「版本号.构建号」命名的）。返回值 <0 表示 a 更旧，>0 表示 a 更新。
int compareVersionStrings(String a, String b) {
  final left = parseVersionParts(a);
  final right = parseVersionParts(b);
  final length = left.length > right.length ? left.length : right.length;
  for (var i = 0; i < length; i++) {
    final x = i < left.length ? left[i] : 0;
    final y = i < right.length ? right[i] : 0;
    if (x == y) continue;
    return x < y ? -1 : 1;
  }
  return 0;
}

/// 远端 [remote] 是否比本地 [local] 更新
bool isNewerVersion(String remote, String local) =>
    compareVersionStrings(remote, local) > 0;

class ApiUpdate {
  /// release.json 与安装包都放在 asset 仓库的 master 分支
  static const String assetPath = 'asset/master/';

  /// 检查更新与下载共用的超时
  static const Duration timeout = Duration(seconds: 3);

  /// 最近一次成功拿到的版本信息，「我」页面的「跳转更新」也用它
  static AppReleaseInfo? latestRelease;

  /// 已经确认可用的代理地址（代理被墙时自动换下一个）
  static String _resolvedProxy = '';

  /// 当前平台是否是 Windows
  static bool get isWindowsPlatform => !kIsWeb && Platform.isWindows;

  /// 远端根地址。
  ///
  /// 注意这里必须是 getter：代理地址是运行时才确定的，
  /// 之前写成 `static final` 会被第一次访问时的空地址永久缓存住，
  /// 之后所有下载链接都会指向错误地址。
  static String get baseUrl => _baseUrlOf(
    _resolvedProxy.isNotEmpty ? _resolvedProxy : AppConfig.stableGithubOrProxy,
  );

  static String _baseUrlOf(String proxy) =>
      proxy.isEmpty ? '' : '$proxy/$assetPath';

  /// 当前平台安装包的下载地址，拿不到版本信息时为空串
  static String get downloadUrl {
    final release = latestRelease;
    if (release == null) return '';
    return getUpdateUrl(release.assetNameFor(isWindows: isWindowsPlatform));
  }

  /// 本地版本号（含构建号），用于和远端版本比较
  static String buildLocalVersion(String version, String buildNumber) {
    final name = version.trim();
    final build = buildNumber.trim();
    if (name.isEmpty) return build;
    if (build.isEmpty) return name;
    return '$name+$build';
  }

  static String getUpdateUrl(String path) {
    final proxy = _resolvedProxy.isNotEmpty
        ? _resolvedProxy
        : AppConfig.stableGithubOrProxy;
    return resolveAssetUrl(proxy, path);
  }

  /// 按代理地址拼出 asset 仓库里的文件地址（下载链接与测试共用）
  static String resolveAssetUrl(String proxy, String path) {
    final base = _baseUrlOf(proxy.trim());
    final name = path.trim();
    if (base.isEmpty || name.isEmpty) return '';
    try {
      return Uri.parse(base).resolve(name).toString();
    } catch (e) {
      return '';
    }
  }

  /// 拉取远端发布信息。
  ///
  /// 优先用已经确认可用的代理；代理没确定或已失效时依次试其它镜像
  /// （AppConfig.githubAndProxy 里是一串备用地址），拿到就记下来给下载用，
  /// 避免「检查更新」在某个代理被墙时整体失效。
  static Future<AppUpdateCheck> checkLatest() async {
    final candidates = <String>[];
    for (final proxy in [
      AppConfig.stableGithubOrProxy,
      ...AppConfig.githubAndProxy,
    ]) {
      final trimmed = proxy.trim();
      if (trimmed.isEmpty || candidates.contains(trimmed)) continue;
      candidates.add(trimmed);
    }
    if (candidates.isEmpty) {
      return const AppUpdateCheck.failure('暂无可用的应用信息源');
    }
    String? lastError;
    for (final proxy in candidates) {
      final result = await _fetchRelease(_baseUrlOf(proxy));
      final release = result.release;
      if (release != null) {
        _resolvedProxy = proxy;
        latestRelease = release;
        return result;
      }
      lastError = result.error;
    }
    return AppUpdateCheck.failure(lastError ?? '获取应用信息失败');
  }

  static Future<AppUpdateCheck> _fetchRelease(String base) async {
    if (base.isEmpty) return const AppUpdateCheck.failure('暂无可用的应用信息源');
    try {
      final url = Uri.parse(base).resolve('release.json').toString();
      final response = await Dio(
        BaseOptions(receiveTimeout: timeout, connectTimeout: timeout),
      ).get(url);
      final data = response.data;
      final release = AppReleaseInfo.fromMap(
        data is String ? jsonDecode(data) : data,
      );
      if (release == null) {
        return const AppUpdateCheck.failure('应用信息格式不正确');
      }
      return AppUpdateCheck.success(release);
    } on DioException catch (e) {
      return AppUpdateCheck.failure(e.message ?? '获取应用信息失败');
    } catch (e) {
      return const AppUpdateCheck.failure('获取应用信息失败');
    }
  }
}

String _asText(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  return value.toString();
}
