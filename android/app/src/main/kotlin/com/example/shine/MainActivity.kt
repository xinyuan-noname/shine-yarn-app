package com.example.shine

import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

/**
 * 接收系统「打开方式」/「用闪纺打开」送来的文档（见 AndroidManifest.xml 里的
 * VIEW intent-filter），交给应用内的阅读器打开。
 *
 * content:// 的读取授权随时可能失效，所以先把内容复制到应用缓存目录，再把本地
 * 路径传给 Dart 侧（lib/services/launch_service.dart）。
 */
class MainActivity : FlutterActivity() {

    companion object {
        /** 与 Dart 侧约定的通道名。 */
        private const val CHANNEL = "shine/launch"

        /** 存放待打开文档的缓存目录名。 */
        private const val CACHE_DIR = "opened_documents"

        /** 超过这个时间的缓存文档会在下次打开时清理。 */
        private const val CACHE_MAX_AGE_MS = 7L * 24 * 60 * 60 * 1000
    }

    private var channel: MethodChannel? = null

    /** Dart 侧就绪前收到的文件先排在这里，等它主动来取。 */
    private val pendingPaths = mutableListOf<String>()

    /** Dart 侧调用过 getInitialFiles 后，才可以直接推送。 */
    private var dartReady = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        )
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                // 冷启动时 Dart 还没开始跑，等它就绪后主动来取排队中的文件。
                "getInitialFiles" -> {
                    dartReady = true
                    result.success(pendingPaths.toList())
                    pendingPaths.clear()
                }

                else -> result.notImplemented()
            }
        }
        channel = methodChannel
        // 冷启动时系统带来的 intent 在这里就能拿到。
        deliverIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // 应用已经运行时，系统会把新的「打开方式」请求送到这里。
        deliverIntent(intent)
    }

    private fun deliverIntent(intent: Intent?) {
        if (intent == null || intent.action != Intent.ACTION_VIEW) {
            return
        }
        val uri = intent.data ?: return
        val path = copyToCache(uri)
        if (path == null) {
            // 读取失败（例如授权已失效）时告知 Dart 侧，避免用户点了没反应。
            if (dartReady) {
                channel?.invokeMethod("openFailed", "无法读取该文件")
            }
            return
        }
        if (dartReady) {
            channel?.invokeMethod("openFile", path)
        } else {
            pendingPaths.add(path)
        }
    }

    /**
     * 把 [uri] 指向的文档复制到应用缓存目录，返回复制后的本地路径；失败返回 null。
     */
    private fun copyToCache(uri: Uri): String? {
        val directory = File(cacheDir, CACHE_DIR)
        if (!directory.isDirectory && !directory.mkdirs()) {
            return null
        }
        removeExpired(directory)
        val target = File(directory, buildFileName(uri))
        return try {
            val source = contentResolver.openInputStream(uri) ?: return null
            source.use { input ->
                FileOutputStream(target).use { output -> input.copyTo(output) }
            }
            target.absolutePath
        } catch (e: Exception) {
            target.delete()
            null
        }
    }

    /** 用文档原名生成缓存文件名，带时间戳以免覆盖正在阅读的文件。 */
    private fun buildFileName(uri: Uri): String {
        val displayName = queryDisplayName(uri) ?: uri.lastPathSegment ?: "document.pdf"
        val simpleName = displayName.substringAfterLast('/')
        val extension = simpleName.substringAfterLast('.', "")
            .takeIf { it.length in 1..5 && it.all { char -> char.isLetterOrDigit() } }
            ?: "pdf"
        val baseName = simpleName.substringBeforeLast('.')
            .replace(Regex("[^\\p{L}\\p{N}_-]+"), "_")
            .trim('_')
            .take(40)
            .ifEmpty { "document" }
        return "$baseName-${System.currentTimeMillis()}.$extension"
    }

    /** 读取文档在文件管理器里显示的名字，读不到时返回 null。 */
    private fun queryDisplayName(uri: Uri): String? {
        return try {
            contentResolver
                .query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                ?.use { cursor -> if (cursor.moveToFirst()) cursor.getString(0) else null }
        } catch (e: Exception) {
            null
        }
    }

    private fun removeExpired(directory: File) {
        val deadline = System.currentTimeMillis() - CACHE_MAX_AGE_MS
        directory.listFiles()?.forEach { file ->
            if (file.lastModified() < deadline) {
                file.delete()
            }
        }
    }
}
