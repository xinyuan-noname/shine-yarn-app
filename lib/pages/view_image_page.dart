import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shine/components/custom_back_handler.dart';
import 'package:shine/services/api.dart';
import 'package:shine/theme.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/utils/share.dart';
import 'package:shine/utils/permission_utils.dart';

class ViewImagePage extends StatefulWidget {
  const ViewImagePage({super.key});

  @override
  State<ViewImagePage> createState() => _ViewImagePageState();
}

class _ViewImagePageState extends State<ViewImagePage> {
  String? _imageUrl;
  String? _filePath;
  Uint8List? _imageData;
  bool _isLoading = true;
  String? _error;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadImage();
    });
  }

  Future<void> _loadImage() async {
    try {
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args is ViewImagePageArgs) {
        setState(() {
          _isLoading = true;
        });

        if (args.filePath != null) {
          // 检查文件是否存在
          final file = File(args.filePath!);
          if (await file.exists()) {
            setState(() {
              _filePath = args.filePath;
              _isLoading = false;
            });
          } else {
            setState(() {
              _error = '图片文件不存在';
              _isLoading = false;
            });
          }
        } else if (args.url != null) {
          setState(() {
            _imageUrl = args.url;
            _isLoading = false;
          });
        } else if (args.data != null) {
          setState(() {
            _imageData = args.data as Uint8List;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = '未提供图片路径';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = '参数错误';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '加载图片失败：${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadImage() async {
    if (_isDownloading) return;

    try {
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
      });

      // 请求存储权限
      final hasPermission = await PermissionUtils.ensureDownloadPermission();
      if (!hasPermission) {
        showToast(msg: '需要存储权限以下载图片');
        setState(() {
          _isDownloading = false;
        });
        return;
      }

      // 获取下载目录
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        showToast(msg: '无法获取存储目录');
        setState(() {
          _isDownloading = false;
        });
        return;
      }

      // 创建保存图片的目录
      final saveDir = Directory('${directory.path}/Download/Shine');
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      // 生成文件名
      final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savePath = '${saveDir.path}/$fileName';

      if (_imageUrl != null) {
        // 使用 Dio 下载图片
        final dio = Dio();
        dio.options.headers.addAll(ApiService.headers.cast<String, String>());

        await dio.download(
          _imageUrl!,
          savePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              setState(() {
                _downloadProgress = received / total;
              });
            }
          },
        );
      } else if (_imageData != null) {
        // 保存内存中的数据
        final file = File(savePath);
        await file.writeAsBytes(_imageData!);
      } else if (_filePath != null) {
        // 复制文件到下载目录
        final sourceFile = File(_filePath!);
        await sourceFile.copy(savePath);
      }

      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });

      // 显示成功提示
      showToast(msg: '图片已保存到：$savePath');

      // 询问是否分享图片
      _showShareDialog(savePath);
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });
      showToast(msg: '下载失败：${e.toString()}');
    }
  }

  void _showShareDialog(String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('下载成功'),
        content: const Text('是否要分享这张图片？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('稍后再说'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              shareImageByXFile(image: XFile(filePath), title: "分享图片");
            },
            icon: const Icon(Icons.share),
            label: const Text('分享'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomBackHandler(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: SizedBox.expand(child: _buildBody()),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        '图片查看',
        style: titleTextStyle.copyWith(fontSize: 18, color: Colors.white),
      ),
      centerTitle: true,
      backgroundColor: deepColorPurple,
      foregroundColor: Colors.white,
      actions: [
        if (!_isLoading && _error == null)
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _isDownloading ? null : _downloadImage,
            tooltip: _isDownloading ? '下载中...' : '下载图片',
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '正在加载图片...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _error = null;
                  _isLoading = true;
                });
                _loadImage();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('重新加载'),
            ),
          ],
        ),
      );
    }
    return InteractiveViewer(
      constrained: false,
      child: Container(alignment: Alignment.center, child: _buildImage()),
    );
  }

  Widget _buildImage() {
    if (_imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: _imageUrl!,
        httpHeaders: ApiService.headers.cast<String, String>(),
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 48, color: Colors.red[300]),
              const SizedBox(height: 8),
              Text('加载失败', style: TextStyle(color: Colors.red[700])),
            ],
          ),
        ),
        fit: BoxFit.contain,
      );
    } else if (_imageData != null) {
      return Image.memory(_imageData!, fit: BoxFit.contain);
    } else if (_filePath != null) {
      return Image.file(File(_filePath!), fit: BoxFit.contain);
    }

    return const Center(child: Text('无法加载图片'));
  }

  Widget _buildBottomBar() {
    if (_isLoading || _error != null) {
      return const SizedBox.shrink();
    }

    if (_isDownloading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                value: _downloadProgress,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  deepColorPurple,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '下载进度：${(_downloadProgress * 100).toStringAsFixed(1)}%',
                style: textFieldStyle.copyWith(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class ViewImagePageArgs {
  final String? filePath;
  final String? url;
  final Uint8List? data;

  const ViewImagePageArgs({this.filePath, this.data, this.url});
}
