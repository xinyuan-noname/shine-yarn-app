import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:internet_file/internet_file.dart';
import 'package:shine/components/custom_back_handler.dart';
import 'package:shine/components/toast.dart';
import 'package:shine/services/api.dart';
import 'package:shine/theme.dart';
import 'package:shine/worker/worker.dart';

class ViewPdfPage extends StatefulWidget {
  const ViewPdfPage({super.key});

  @override
  State<ViewPdfPage> createState() => _ViewPdfPageState();
}

class _ViewPdfPageState extends State<ViewPdfPage> {
  PdfController? _pdfController;
  int _currentPage = 1;
  int _totalPages = 0;
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
      _loadPdf();
    });
  }

  Future<void> _loadPdf() async {
    try {
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args is ViewPdfPageArgs) {
        setState(() {
          _isLoading = true;
        });

        if (args.filePath != null) {
          final document = await PdfDocument.openFile(args.filePath!);
          _pdfController = PdfController(document: Future.value(document));

          setState(() {
            _totalPages = document.pagesCount;
            _isLoading = false;
          });
        } else if (args.url != null) {
          _url = args.url;
          if (args.filename is String) {
            _filename = args.filename;
          }
          if (args.downloadUrl is String) {
            _downloadUrl = args.downloadUrl;
          }
          _downloadable = args.downloadable;
          final fileData = await InternetFile.get(
            args.url!,
            headers: ApiService.headers.cast<String, String>(),
          );
          final document = await PdfDocument.openData(fileData);
          _pdfController = PdfController(document: Future.value(document));

          setState(() {
            _totalPages = document.pagesCount;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = '未提供 PDF 文件路径';
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
        _error = '加载 PDF 失败：${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomBackHandler(
      onWillPop: () async {
        _pdfController?.dispose();
        return true;
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        '文档查看',
        style: titleTextStyle.copyWith(fontSize: 18, color: bgColorLight),
      ),
      centerTitle: true,
      backgroundColor: deepColorPurple,
      foregroundColor: bgColorLight,
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
            tooltip: '下载pdf',
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '正在加载文档...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Expanded(
              child: Text(
                _error!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  overflow: TextOverflow.ellipsis,
                ),
                textAlign: TextAlign.center,
                maxLines: 10,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _error = null;
                  _isLoading = true;
                });
                _loadPdf();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    if (_pdfController == null) {
      return const Center(
        child: Text(
          '无法加载 PDF 文档',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      );
    }

    return PdfView(
      controller: _pdfController!,
      onPageChanged: (page) {
        setState(() {
          _currentPage = page;
        });
      },
    );
  }

  Widget _buildBottomBar() {
    if (_isLoading || _error != null || _pdfController == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColorLight,
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '第 $_currentPage / $_totalPages 页',
              style: textFieldStyle.copyWith(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: _currentPage > 1
                      ? () {
                          _pdfController!.animateToPage(
                            _currentPage - 1,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.ease,
                          );
                        }
                      : null,
                  tooltip: '上一页',
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: _currentPage < _totalPages
                      ? () {
                          _pdfController!.animateToPage(
                            _currentPage + 1,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.ease,
                          );
                        }
                      : null,
                  tooltip: '下一页',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }
}

class ViewPdfPageArgs {
  final String? filePath;
  final String? url;
  final bool downloadable;
  final String? downloadUrl;
  final String? filename;

  const ViewPdfPageArgs({
    this.filePath,
    this.url,
    this.downloadable = false,
    this.downloadUrl,
    this.filename,
  });
}
