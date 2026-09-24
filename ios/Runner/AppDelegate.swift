import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  /// 与 Dart 侧约定的通道名，见 lib/services/launch_service.dart。
  private static let launchChannelName = "shine/launch"

  private var launchChannel: FlutterMethodChannel?

  /// Dart 侧就绪前收到的文件先排在这里，等它主动来取。
  private var pendingPaths: [String] = []

  /// Dart 侧调用过 getInitialFiles 后，才可以直接推送。
  private var dartReady = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let messenger = launchBinaryMessenger() {
      let channel = FlutterMethodChannel(
        name: AppDelegate.launchChannelName,
        binaryMessenger: messenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self = self else {
          result(nil)
          return
        }
        if call.method == "getInitialFiles" {
          // 冷启动时 Dart 还没开始跑，等它就绪后主动来取排队中的文件。
          self.dartReady = true
          let files = self.pendingPaths
          self.pendingPaths.removeAll()
          result(files)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
      launchChannel = channel
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// 取引擎的消息通道。
  ///
  /// 优先走 registrar，和 GeneratedPluginRegistrant 注册插件是同一条路；
  /// 取不到时退回根 FlutterViewController。
  private func launchBinaryMessenger() -> FlutterBinaryMessenger? {
    let registrar: FlutterPluginRegistrar? = self.registrar(
      forPlugin: "ShineLaunchPlugin"
    )
    if let messenger = registrar?.messenger() {
      return messenger
    }
    return (window?.rootViewController as? FlutterViewController)?.binaryMessenger
  }

  /// 「用闪纺打开」/ 从「文件」App 打开 PDF 时系统会调用这里。
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if openDocument(at: url) {
      return true
    }
    return super.application(app, open: url, options: options)
  }

  /// 把外部文档复制进应用沙盒，返回是否处理成功。
  ///
  /// 外部文件的位置与授权随时可能失效，复制一份之后再交给 Dart 侧按普通本地
  /// 文件打开。
  private func openDocument(at url: URL) -> Bool {
    guard url.isFileURL else {
      return false
    }
    let scoped = url.startAccessingSecurityScopedResource()
    defer {
      if scoped {
        url.stopAccessingSecurityScopedResource()
      }
    }

    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("opened_documents", isDirectory: true)
    try? FileManager.default.createDirectory(
      at: directory,
      withIntermediateDirectories: true
    )
    let target = directory.appendingPathComponent(
      "\(Int(Date().timeIntervalSince1970 * 1000))-\(url.lastPathComponent)"
    )
    do {
      if FileManager.default.fileExists(atPath: target.path) {
        try FileManager.default.removeItem(at: target)
      }
      try FileManager.default.copyItem(at: url, to: target)
      deliver(path: target.path)
    } catch {
      // 复制失败时退回原路径，能读就直接读。
      deliver(path: url.path)
    }
    return true
  }

  private func deliver(path: String) {
    if dartReady {
      launchChannel?.invokeMethod("openFile", arguments: path)
    } else {
      pendingPaths.append(path)
    }
  }
}
