import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shine/components/line.dart';
import 'package:shine/theme.dart';

class ToolBaseConverterPage extends StatefulWidget {
  const ToolBaseConverterPage({super.key});

  @override
  State<ToolBaseConverterPage> createState() => _ToolBaseConverterPageState();
}

class _ToolBaseConverterPageState extends State<ToolBaseConverterPage> {
  final TextEditingController _inputController = TextEditingController(text: '1010');
  int _inputBase = 2;
  int _outputBase = 10;
  String _result = '';
  String _error = '';

  static const List<int> _bases = [2, 8, 10, 16];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('进制转换', style: titleTextStyle),
        centerTitle: true,
        bottom: bottomLine,
      ),
      body: SafeArea(
        child: ListView(
          padding: bodyPadding,
          children: [
            _buildInputCard(),
            const SizedBox(height: 12),
            _buildResultCard(),
            const SizedBox(height: 12),
            _buildHintCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [greyBoxShadow],
        gradient: whiteLinearGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('输入数值', style: labelStyle),
          const SizedBox(height: 8),
          TextField(
            controller: _inputController,
            keyboardType: TextInputType.text,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-FxX+\-]')),
            ],
            decoration: const InputDecoration(
              hintText: '例如：1010、FF、755、255',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildBaseDropdown(
                  label: '输入进制',
                  value: _inputBase,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _inputBase = value;
                        _result = '';
                        _error = '';
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBaseDropdown(
                  label: '输出进制',
                  value: _outputBase,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _outputBase = value;
                        _result = '';
                        _error = '';
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: _convert,
                child: const Text('转换'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _inputController.clear();
                    _result = '';
                    _error = '';
                  });
                },
                child: const Text('清空'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBaseDropdown({
    required String label,
    required int value,
    required ValueChanged<int?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        DropdownButton<int>(
          value: value,
          isExpanded: true,
          items: [
            for (final base in _bases)
              DropdownMenuItem(
                value: base,
                child: Text('${base} 进制'),
              ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    if (_error.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [greyBoxShadow],
          gradient: whiteLinearGradient,
        ),
        child: Text(
          _error,
          style: const TextStyle(color: Colors.red, fontSize: 14),
        ),
      );
    }
    if (_result.isEmpty) {
      return const SizedBox.shrink();
    }
    final parsed = _parseValue();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [greyBoxShadow],
        gradient: whiteLinearGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '转换结果',
            style: TextStyle(
              fontFamily: 'SmileySans',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Divider(height: 20),
          _buildValueRow('二进制', parsed?.toRadixString(2) ?? '—'),
          _buildValueRow('八进制', parsed?.toRadixString(8) ?? '—'),
          _buildValueRow('十进制', parsed?.toRadixString(10) ?? '—'),
          _buildValueRow(
            '十六进制',
            parsed == null ? '—' : parsed.toRadixString(16).toUpperCase(),
          ),
          const SizedBox(height: 10),
          Text(
            '输出结果（$_outputBase 进制）：${_result.toUpperCase()}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [greyBoxShadow],
        gradient: whiteLinearGradient,
      ),
      child: const Text(
        '说明：支持二进制（BIN）、八进制（OCT）、十进制（DEC）和十六进制（HEX）之间的相互转换。'
        '输入十六进制时可使用 0-9 和 A-F，不区分大小写。',
        style: TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
      ),
    );
  }

  void _convert() {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _error = '请输入需要转换的数值';
        _result = '';
      });
      return;
    }
    final parsed = _parseValue();
    if (parsed == null) {
      setState(() {
        _error = '输入的值不是有效的 $_inputBase 进制数';
        _result = '';
      });
      return;
    }
    setState(() {
      _error = '';
      _result = parsed.toRadixString(_outputBase);
    });
  }

  BigInt? _parseValue() {
    var input = _inputController.text.trim().toUpperCase();
    if (input.isEmpty) return null;
    var negative = false;
    if (input.startsWith('-')) {
      negative = true;
      input = input.substring(1);
    } else if (input.startsWith('+')) {
      input = input.substring(1);
    }
    if (_inputBase == 16 && input.startsWith('0X')) {
      input = input.substring(2);
    }
    if (input.isEmpty) return null;
    if (_inputBase == 2 && !RegExp(r'^[01]+$').hasMatch(input)) return null;
    if (_inputBase == 8 && !RegExp(r'^[0-7]+$').hasMatch(input)) return null;
    if (_inputBase == 10 && !RegExp(r'^[0-9]+$').hasMatch(input)) return null;
    if (_inputBase == 16 && !RegExp(r'^[0-9A-F]+$').hasMatch(input)) return null;
    try {
      final value = BigInt.parse(input, radix: _inputBase);
      return negative ? -value : value;
    } catch (_) {
      return null;
    }
  }
}
