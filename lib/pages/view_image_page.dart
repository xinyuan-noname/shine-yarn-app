import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/services/api.dart';
import 'package:shine/theme.dart';
import 'package:shine/worker/worker.dart';

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
   String? _url;
  bool _downloadable = false;
  String? _downloadUrl;
  String? _filename;

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
          _url = args.url;
          if (args.filename is String) {
            _filename = args.filename;
          }
          if (args.downloadUrl is String) {
            _downloadUrl = args.downloadUrl;
          }
          _downloadable = args.downloadable;
          setState(() {
            _imageUrl = args.url;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Container(alignment: Alignment.center, child: _buildBody()),
      ),
      bottomNavigationBar: _buildBottomBar(),
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
        if (!_isLoading && _error == null && _downloadable)
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              final String? downloadUrl = _downloadUrl ?? _url;
              if (downloadUrl is String && _filename is String) {
                Worker.startDownload(url: downloadUrl, filename: _filename!);
                showToast(msg: "已开始下载$_filename");
              }
            },
            tooltip: '下载图片',
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
  final bool downloadable;
  final String? downloadUrl;
  final String? filename;

  const ViewImagePageArgs({
    this.filePath,
    this.url,
    this.downloadable = false,
    this.downloadUrl,
    this.filename,
  });
}
