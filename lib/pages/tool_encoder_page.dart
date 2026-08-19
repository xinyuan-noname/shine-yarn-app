import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shine/components/line.dart';
import 'package:shine/theme.dart';

class ToolEncoderPage extends StatefulWidget {
  const ToolEncoderPage({super.key});

  @override
  State<ToolEncoderPage> createState() => _ToolEncoderPageState();
}

class _ToolEncoderPageState extends State<ToolEncoderPage> {
  String _selectedId = 'pcm';
  final TextEditingController _inputController = TextEditingController();
  String _result = '';

  final List<_EncoderItem> _items = const [
    _EncoderItem('pcm', 'PCM A律13折线编码', 'PCM / 信源编码'),
    _EncoderItem('source', '香农码 / 费诺码 / 哈夫曼码', '信源编码'),
    _EncoderItem('hamming', '汉明码 (7,4)', '信道编码'),
    _EncoderItem('cyclic', '循环码', '信道编码'),
    _EncoderItem('conv', '卷积码', '信道编码'),
    _EncoderItem('line', 'AMI码 / HDB3码', '线路编码'),
    _EncoderItem('mod', 'ASK / FSK / PSK', '数字调制'),
  ];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编码器', style: titleTextStyle),
        centerTitle: true,
        bottom: bottomLine,
      ),
      body: SafeArea(
        child: ListView(
          padding: bodyPadding,
          children: [
            _buildSelectorCard(),
            const SizedBox(height: 12),
            _buildDetail(),
            const SizedBox(height: 12),
            _buildHintCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorCard() {
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
          const Text('选择编码类型', style: labelStyle),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: _selectedId,
            isExpanded: true,
            items: [
              for (final item in _items)
                DropdownMenuItem(
                  value: item.id,
                  child: Text(
                    '${item.category} · ${item.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedId = value;
                  _result = '';
                  _inputController.clear();
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetail() {
    switch (_selectedId) {
      case 'pcm':
        return _buildInteractiveCard(
          title: 'PCM A律13折线编码',
          hint: '输入采样值（-2048 ~ 2047），例如 -1320 或 256',
          compute: _computePcm,
        );
      case 'source':
        return _buildInteractiveCard(
          title: '香农码 / 费诺码 / 哈夫曼码',
          hint: '输入概率或频次，逗号分隔，例如 0.4,0.2,0.2,0.1,0.1',
          compute: _computeSourceCodes,
        );
      case 'hamming':
        return _buildInteractiveCard(
          title: '汉明码 (7,4)',
          hint: '输入任意位数数据，例如 1010 或 10101010',
          compute: _computeHamming,
        );
      case 'line':
        return _buildInteractiveCard(
          title: 'AMI码 / HDB3码',
          hint: '输入二进制序列，例如 1011000',
          compute: _computeLineCodes,
        );
      case 'mod':
        return _buildInteractiveCard(
          title: 'ASK / FSK / PSK',
          hint: '输入二进制序列，例如 1010',
          compute: _computeModulation,
        );
      case 'cyclic':
        return _buildCyclicCard();
      case 'conv':
        return _buildConvolutionalCard();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInteractiveCard({
    required String title,
    required String hint,
    required String Function(String) compute,
  }) {
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
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'SmileySans',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _inputController,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onSubmitted: (_) {
              setState(() {
                _result = compute(_inputController.text);
              });
            },
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _result = compute(_inputController.text);
              });
            },
            child: const Text('编码'),
          ),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: mainColorGrey40),
              ),
              child: Text(
                _result,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCyclicCard() {
    return _buildReferenceCard(
      title: '循环码',
      lines: const [
        '循环码是线性分组码，任一码字循环移位后仍是码字。',
        '生成多项式 g(x)，信息多项式 m(x)，编码为：',
        'C(x) = x^(n-k)·m(x) + r(x)',
        '其中 r(x) 是 x^(n-k)·m(x) 对 g(x) 取模的余式。',
        '',
        '例：(7,4) 循环码，g(x) = x³ + x + 1',
        '信息 1010 编码后得到码字 1010001（示例）。',
      ],
    );
  }

  Widget _buildConvolutionalCard() {
    return _buildReferenceCard(
      title: '卷积码',
      lines: const [
        '卷积码是有记忆的信道编码，输出不仅与当前输入有关，还与前面若干位有关。',
        '常用 (n,k,K) 表示：k 位输入，n 位输出，约束长度 K。',
        '例：(2,1,2) 卷积码',
        '生成多项式：g1 = 111，g2 = 101',
        '编码输出 = 输入序列与生成多项式的模2卷积。',
        '可用状态图、网格图或 Viterbi 算法进行译码。',
      ],
    );
  }

  Widget _buildReferenceCard({
    required String title,
    required List<String> lines,
  }) {
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
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'SmileySans',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Divider(height: 20),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                line,
                style: const TextStyle(fontSize: 14, height: 1.5),
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
        '说明：本工具面向通信专业学生，涵盖 PCM、信源编码、信道编码、线路编码和数字调制。'
        '可输入参数实时计算，也可查看原理说明。',
        style: TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
      ),
    );
  }

  // ---------- 计算函数 ----------

  String _computePcm(String raw) {
    final input = raw.trim().replaceAll(' ', '');
    final value = int.tryParse(input);
    if (value == null) {
      return '请输入整数采样值';
    }
    if (value < -2048 || value > 2047) {
      return '输入范围：-2048 ~ 2047';
    }
    final sign = value >= 0 ? 1 : 0;
    final abs = value.abs();
    const boundaries = [0, 16, 32, 64, 128, 256, 512, 1024, 2048];
    var seg = 8;
    for (var i = 0; i < 8; i++) {
      if (abs >= boundaries[i] && abs < boundaries[i + 1]) {
        seg = i + 1;
        break;
      }
    }
    final lower = boundaries[seg - 1];
    final upper = boundaries[seg];
    final step = (upper - lower) / 16;
    final intra = (((abs - lower) / step).floor()).clamp(0, 15).toInt();
    final segCode = (seg - 1).toRadixString(2).padLeft(3, '0');
    final intraCode = intra.toRadixString(2).padLeft(4, '0');
    final code = '$sign$segCode$intraCode';
    return '8位PCM码：$code\n极性码=$sign，段落码=$segCode，段内码=$intraCode';
  }

  String _computeSourceCodes(String raw) {
    final probs = _parseProbabilities(raw);
    if (probs.isEmpty) {
      return '请输入至少两个概率或频次，用逗号分隔';
    }
    final huffman = _huffmanCodes(probs);
    final shannon = _shannonCodes(probs);
    final fano = _fanoCodes(probs);
    return '输入概率：${probs.map((p) => p.toStringAsFixed(3)).join(', ')}\n\n'
        '【哈夫曼码】\n${_formatCodes(huffman)}\n\n'
        '【香农码】\n${_formatCodes(shannon)}\n\n'
        '【费诺码】\n${_formatCodes(fano)}';
  }

  List<double> _parseProbabilities(String raw) {
    final parts = raw.trim().split(RegExp(r'[,，\s]+'));
    final nums = <double>[];
    for (final part in parts) {
      final v = double.tryParse(part);
      if (v != null && v > 0) {
        nums.add(v);
      }
    }
    if (nums.length < 2) {
      return [];
    }
    final sum = nums.reduce((a, b) => a + b);
    return nums.map((n) => n / sum).toList();
  }

  String _formatCodes(List<_CodeEntry> codes) {
    return codes.map((e) => '${e.name}: ${e.code}').join('\n');
  }

  List<_CodeEntry> _huffmanCodes(List<double> probs) {
    final nodes = <_HNode>[
      for (var i = 0; i < probs.length; i++)
        _HNode(name: 'S${i + 1}', weight: probs[i]),
    ];
    while (nodes.length > 1) {
      nodes.sort((a, b) => a.weight.compareTo(b.weight));
      final left = nodes.removeAt(0);
      final right = nodes.removeAt(0);
      nodes.add(
        _HNode(
          weight: left.weight + right.weight,
          left: left,
          right: right,
        ),
      );
    }
    final result = <_CodeEntry>[];
    void traverse(_HNode? node, String code) {
      if (node == null) return;
      if (node.left == null && node.right == null) {
        result.add(_CodeEntry(node.name!, code));
        return;
      }
      traverse(node.left, '${code}0');
      traverse(node.right, '${code}1');
    }

    traverse(nodes.first, '');
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  List<_CodeEntry> _shannonCodes(List<double> probs) {
    final items = <_ProbItem>[
      for (var i = 0; i < probs.length; i++)
        _ProbItem(name: 'S${i + 1}', prob: probs[i]),
    ];
    items.sort((a, b) => b.prob.compareTo(a.prob));
    final result = <_CodeEntry>[];
    var cum = 0.0;
    for (final item in items) {
      final length = (-math.log(item.prob) / math.ln2).ceil();
      final code = _fractionBits(cum, length);
      result.add(_CodeEntry(item.name, code));
      cum += item.prob;
    }
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  List<_CodeEntry> _fanoCodes(List<double> probs) {
    final items = <_ProbItem>[
      for (var i = 0; i < probs.length; i++)
        _ProbItem(name: 'S${i + 1}', prob: probs[i]),
    ];
    items.sort((a, b) => b.prob.compareTo(a.prob));
    final result = <_CodeEntry>[];

    void fano(List<_ProbItem> list, String code) {
      if (list.length == 1) {
        result.add(_CodeEntry(list.first.name, code));
        return;
      }
      var total = 0.0;
      for (final item in list) {
        total += item.prob;
      }
      var leftSum = 0.0;
      var split = 1;
      var bestDiff = double.infinity;
      for (var i = 0; i < list.length - 1; i++) {
        leftSum += list[i].prob;
        final diff = (total - 2 * leftSum).abs();
        if (diff < bestDiff) {
          bestDiff = diff;
          split = i + 1;
        }
      }
      fano(list.sublist(0, split), '${code}0');
      fano(list.sublist(split), '${code}1');
    }

    fano(items, '');
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  String _fractionBits(double value, int bits) {
    var v = value;
    var s = '';
    for (var i = 0; i < bits; i++) {
      v *= 2;
      final bit = v >= 1 ? 1 : 0;
      s += '$bit';
      v -= bit.toDouble();
    }
    return s;
  }

  String _computeHamming(String raw) {
    final input = raw.trim().replaceAll(' ', '');
    if (!RegExp(r'^[01]{4}$').hasMatch(input)) {
      return '请输入4位二进制数据，例如 1010';
    }
    final d1 = int.parse(input[0]);
    final d2 = int.parse(input[1]);
    final d3 = int.parse(input[2]);
    final d4 = int.parse(input[3]);
    final p1 = d1 ^ d2 ^ d4;
    final p2 = d1 ^ d3 ^ d4;
    final p3 = d2 ^ d3 ^ d4;
    final code = '$p1$p2$d1$p3$d2$d3$d4';
    return '汉明码(7,4)：$code\n校验位：p1=$p1, p2=$p2, p3=$p3';
  }

  String _computeLineCodes(String raw) {
    final input = raw.trim().replaceAll(' ', '');
    if (!RegExp(r'^[01]+$').hasMatch(input)) {
      return '请输入二进制序列，例如 1011000';
    }
    final ami = _amiEncode(input);
    final hdb3 = _hdb3Encode(input);
    return 'AMI码：$ami\nHDB3码：$hdb3';
  }

  String _amiEncode(String bits) {
    var polarity = -1; // 先取反，使第一个 1 为 +
    var out = '';
    for (final ch in bits.split('')) {
      if (ch == '1') {
        polarity = -polarity;
        out += polarity > 0 ? '+' : '-';
      } else {
        out += '0';
      }
    }
    return out;
  }

  String _hdb3Encode(String bits) {
    var lastPolarity = -1; // 使第一个 1 为 +
    var nonZeroSinceSub = 0;
    var zeroCount = 0;
    final out = <String>[];

    for (final ch in bits.split('')) {
      if (ch == '1') {
        for (var i = 0; i < zeroCount; i++) {
          out.add('0');
        }
        zeroCount = 0;
        lastPolarity = -lastPolarity;
        out.add(lastPolarity > 0 ? '+' : '-');
        nonZeroSinceSub++;
      } else {
        zeroCount++;
        if (zeroCount == 4) {
          if (nonZeroSinceSub % 2 == 1) {
            out.add('0');
            out.add('0');
            out.add('0');
            out.add(lastPolarity > 0 ? '+' : '-');
            nonZeroSinceSub = 0;
          } else {
            final bPolarity = -lastPolarity;
            out.add(bPolarity > 0 ? '+' : '-');
            out.add('0');
            out.add('0');
            out.add(bPolarity > 0 ? '+' : '-');
            lastPolarity = bPolarity;
            nonZeroSinceSub = 0;
          }
          zeroCount = 0;
        }
      }
    }
    for (var i = 0; i < zeroCount; i++) {
      out.add('0');
    }
    return out.join();
  }

  String _computeModulation(String raw) {
    final input = raw.trim().replaceAll(' ', '');
    if (!RegExp(r'^[01]+$').hasMatch(input)) {
      return '请输入二进制序列，例如 1010';
    }
    final ask = input
        .split('')
        .map((b) => b == '1' ? 'A·cos(ωc·t)' : '0')
        .join(' | ');
    final fsk = input
        .split('')
        .map((b) => b == '1' ? 'cos(ω1·t)' : 'cos(ω2·t)')
        .join(' | ');
    final psk = input
        .split('')
        .map((b) => b == '1' ? 'cos(ωc·t + π)' : 'cos(ωc·t)')
        .join(' | ');
    return 'ASK：$ask\nFSK：$fsk\nPSK：$psk';
  }
}

class _EncoderItem {
  final String id;
  final String name;
  final String category;

  const _EncoderItem(this.id, this.name, this.category);
}

class _CodeEntry {
  final String name;
  final String code;

  _CodeEntry(this.name, this.code);
}

class _ProbItem {
  final String name;
  final double prob;

  _ProbItem({required this.name, required this.prob});
}

class _HNode {
  final String? name;
  final double weight;
  final _HNode? left;
  final _HNode? right;

  _HNode({
    this.name,
    required this.weight,
    this.left,
    this.right,
  });
}
