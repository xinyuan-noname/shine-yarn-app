import 'package:flutter_test/flutter_test.dart';
import 'package:shine/services/api_update.dart';

void main() {
  group('release.json 解析', () {
    test('正常内容解析出各字段', () {
      final release = AppReleaseInfo.fromMap({
        'apk': '1.0.1.11.apk',
        'setup': '1.0.0.exe',
        'version': '1.0.1.11',
        'forceUpdate': true,
        'info': '修了几个问题',
      });
      expect(release, isNotNull);
      expect(release!.apk, '1.0.1.11.apk');
      expect(release.setup, '1.0.0.exe');
      expect(release.version, '1.0.1.11');
      expect(release.forceUpdate, isTrue);
      expect(release.displayInfo, '修了几个问题');
    });

    test('字段缺失或类型不对时不再抛异常', () {
      // 以前这里直接 as String / as bool，少一个字段就会在首页初始化时炸掉
      final release = AppReleaseInfo.fromMap({'apk': 123});
      expect(release, isNotNull);
      expect(release!.apk, '123');
      expect(release.setup, '');
      expect(release.version, '');
      expect(release.forceUpdate, isFalse);
      expect(release.displayInfo, '本次更新没有附带说明');
    });

    test('forceUpdate 写成字符串也认', () {
      final release = AppReleaseInfo.fromMap({
        'version': '2.0.0',
        'forceUpdate': 'true',
      });
      expect(release!.forceUpdate, isTrue);
    });

    test('不是对象或没有任何关键字段时返回 null', () {
      expect(AppReleaseInfo.fromMap(null), isNull);
      expect(AppReleaseInfo.fromMap('not a json'), isNull);
      expect(AppReleaseInfo.fromMap([1, 2, 3]), isNull);
      expect(AppReleaseInfo.fromMap({'info': '只有说明'}), isNull);
    });
  });

  group('版本号比较', () {
    test('逐段比较数字', () {
      expect(compareVersionStrings('1.0.1', '1.0.0'), greaterThan(0));
      expect(compareVersionStrings('1.0.0', '1.0.1'), lessThan(0));
      expect(compareVersionStrings('1.0.1', '1.0.1'), 0);
      expect(compareVersionStrings('1.10.0', '1.9.9'), greaterThan(0));
    });

    test('段数不同时缺的按 0 算', () {
      expect(compareVersionStrings('1.0.1', '1.0.1.0'), 0);
      expect(compareVersionStrings('1.0.1.11', '1.0.1'), greaterThan(0));
    });

    test('带构建号的写法也参与比较（1.0.1+10 与 1.0.1.11）', () {
      expect(compareVersionStrings('1.0.1+10', '1.0.1.10'), 0);
      expect(compareVersionStrings('1.0.1.11', '1.0.1+10'), greaterThan(0));
      expect(isNewerVersion('1.0.1.11', '1.0.1+10'), isTrue);
      expect(isNewerVersion('1.0.1.10', '1.0.1+10'), isFalse);
    });

    test('取不到数字时按 0 处理，不会抛异常', () {
      expect(compareVersionStrings('', ''), 0);
      expect(compareVersionStrings('v1.0.0', '1.0.0'), 0);
      expect(compareVersionStrings('abc', '1.0.0'), lessThan(0));
    });
  });

  group('远端版本判定', () {
    const release = AppReleaseInfo(
      apk: '1.0.1.11.apk',
      setup: '1.0.0.exe',
      version: '1.0.0',
    );

    test('文件名里的版本比声明版本新时用文件名', () {
      // asset 仓库里就出现过「挂了新包但没改 version」的情况
      expect(release.versionFor(isWindows: false), '1.0.1.11');
    });

    test('声明版本更新时用声明版本', () {
      const newer = AppReleaseInfo(apk: '1.0.1.1.apk', version: '1.2.0');
      expect(newer.versionFor(isWindows: false), '1.2.0');
    });

    test('文件名里没有版本号时用声明版本', () {
      const plain = AppReleaseInfo(apk: 'shine.apk', version: '1.0.2');
      expect(plain.versionFor(isWindows: false), '1.0.2');
    });

    test('按平台取对应的安装包名', () {
      expect(release.assetNameFor(isWindows: false), '1.0.1.11.apk');
      expect(release.assetNameFor(isWindows: true), '1.0.0.exe');
      // Windows 包只有 1.0.0，比本地的 1.0.1+10 旧，不提示更新
      expect(release.isNewerThan('1.0.1+10', isWindows: true), isFalse);
      expect(release.isNewerThan('1.0.1+10', isWindows: false), isTrue);
    });

    test('已经是最新版时不提示', () {
      expect(release.isNewerThan('1.0.1.11', isWindows: false), isFalse);
      expect(release.isNewerThan('1.0.2', isWindows: false), isFalse);
    });

    test('文件名版本解析', () {
      expect(AppReleaseInfo.versionOfAsset('1.0.1.11.apk'), '1.0.1.11');
      expect(AppReleaseInfo.versionOfAsset('shine-v2.3.apk'), '2.3');
      expect(AppReleaseInfo.versionOfAsset('shine.apk'), '');
    });
  });

  group('下载地址拼接', () {
    const proxy = 'https://raw.githubusercontent.com/xinyuan-noname';

    test('按代理地址拼出仓库里的安装包地址', () {
      expect(
        ApiUpdate.resolveAssetUrl(proxy, '1.0.1.11.apk'),
        '$proxy/asset/master/1.0.1.11.apk',
      );
    });

    test('代理地址或文件名缺失时返回空串', () {
      expect(ApiUpdate.resolveAssetUrl('', 'a.apk'), '');
      expect(ApiUpdate.resolveAssetUrl(proxy, '   '), '');
    });

    test('本地版本号带上构建号', () {
      expect(ApiUpdate.buildLocalVersion('1.0.1', '10'), '1.0.1+10');
      expect(ApiUpdate.buildLocalVersion('1.0.1', ''), '1.0.1');
      expect(ApiUpdate.buildLocalVersion('', '10'), '10');
      expect(ApiUpdate.buildLocalVersion('', ''), '');
    });
  });
}
