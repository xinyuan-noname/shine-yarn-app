import 'package:flutter/material.dart';
import 'package:shine/components/line.dart';
import 'package:shine/theme.dart';

class ToolKarnaughMapPage extends StatefulWidget {
  const ToolKarnaughMapPage({super.key});

  @override
  State<ToolKarnaughMapPage> createState() => _ToolKarnaughMapPageState();
}

class _ToolKarnaughMapPageState extends State<ToolKarnaughMapPage> {
  int _variableCount = 3;
  final List<String> _order = ['A', 'B', 'C', 'D'];
  final Map<int, String> _cells = {};
  String? _selectedTool; // null = 循环模式；'' = 空白；'0' / '1' / 'd'

  List<String> get _activeOrder => _order.sublist(0, _variableCount);

  List<int> _grayCodes(int bits) {
    final total = 1 << bits;
    return List<int>.generate(total, (i) => i ^ (i >> 1));
  }

  _KmapLayout _getLayout(int n, List<String> order) {
    if (n == 2) {
      return _KmapLayout(
        colBits: 1,
        rowBits: 1,
        colVars: [order[0]],
        rowVars: [order[1]],
      );
    }
    if (n == 3) {
      return _KmapLayout(
        colBits: 2,
        rowBits: 1,
        colVars: [order[1], order[2]],
        rowVars: [order[0]],
      );
    }
    return _KmapLayout(
      colBits: 2,
      rowBits: 2,
      colVars: [order[0], order[1]],
      rowVars: [order[2], order[3]],
    );
  }

  int _cellIndex(_KmapLayout layout, int colGray, int rowGray) {
    final order = _activeOrder;
    var index = 0;
    for (final variable in order) {
      final colIndex = layout.colVars.indexOf(variable);
      int bit;
      if (colIndex >= 0) {
        bit = (colGray >> (layout.colBits - 1 - colIndex)) & 1;
      } else {
        final rowIndex = layout.rowVars.indexOf(variable);
        bit = (rowGray >> (layout.rowBits - 1 - rowIndex)) & 1;
      }
      index = (index << 1) | bit;
    }
    return index;
  }

  void _changeVariableCount(int? value) {
    if (value == null || value == _variableCount) return;
    setState(() {
      _variableCount = value;
      _cells.clear();
      _selectedTool = null;
    });
  }

  void _swapOrderAt(int position, String value) {
    if (value == _order[position]) return;
    final oldPosition = _order.indexOf(value);
    if (oldPosition < 0) return;
    setState(() {
      _order[oldPosition] = _order[position];
      _order[position] = value;
      _cells.clear();
    });
  }

  void _clear() {
    setState(() {
      _cells.clear();
      _selectedTool = null;
    });
  }

  void _handleCellTap(int index) {
    final current = _cells[index] ?? '';
    String next;
    if (_selectedTool != null) {
      next = _selectedTool!;
    } else {
      const order = ['', '0', '1', 'd'];
      final pos = order.indexOf(current);
      next = order[(pos + 1) % order.length];
    }
    setState(() {
      if (next.isEmpty) {
        _cells.remove(index);
      } else {
        _cells[index] = next;
      }
    });
  }

  String _bits(int value, int bits) {
    return value.toRadixString(2).padLeft(bits, '0');
  }

  String _mintermAlgebraic(int index, List<String> order) {
    final bits = _bits(index, order.length);
    final terms = <String>[];
    for (var i = 0; i < order.length; i++) {
      terms.add(bits[i] == '1' ? order[i] : "${order[i]}'");
    }
    return terms.join('');
  }

  String _maxtermAlgebraic(int index, List<String> order) {
    final bits = _bits(index, order.length);
    final terms = <String>[];
    for (var i = 0; i < order.length; i++) {
      terms.add(bits[i] == '0' ? order[i] : "${order[i]}'");
    }
    return '(${terms.join(' + ')})';
  }

  String _mintermsAlgebraic(List<int> minterms, List<String> order) {
    return minterms.map((m) => _mintermAlgebraic(m, order)).join(' + ');
  }

  String _maxtermsAlgebraic(List<int> maxterms, List<String> order) {
    return maxterms.map((m) => _maxtermAlgebraic(m, order)).join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final order = _activeOrder;
    final layout = _getLayout(_variableCount, order);

    return Scaffold(
      appBar: AppBar(
        title: const Text('卡诺图', style: titleTextStyle),
        centerTitle: true,
        bottom: bottomLine,
      ),
      body: SafeArea(
        child: ListView(
          padding: bodyPadding,
          children: [
            _buildControlCard(order),
            const SizedBox(height: 12),
            _buildMapCard(layout),
            const SizedBox(height: 12),
            _buildResultCard(order),
          ],
        ),
      ),
    );
  }

  Widget _buildControlCard(List<String> order) {
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
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('变量数量：', style: labelStyle),
              DropdownButton<int>(
                value: _variableCount,
                items: const [
                  DropdownMenuItem(value: 2, child: Text('2 变量')),
                  DropdownMenuItem(value: 3, child: Text('3 变量')),
                  DropdownMenuItem(value: 4, child: Text('4 变量')),
                ],
                onChanged: _changeVariableCount,
              ),
              const SizedBox(width: 4),
              const Text('变量顺序(高位→低位)：', style: labelStyle),
              for (var i = 0; i < _variableCount; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: DropdownButton<String>(
                    value: order[i],
                    underline: const SizedBox.shrink(),
                    items: [
                      for (final variable in order)
                        DropdownMenuItem(
                          value: variable,
                          child: Text(variable),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) _swapOrderAt(i, value);
                    },
                  ),
                ),
              TextButton(onPressed: _clear, child: const Text('清空')),
            ],
          ),
          const Divider(height: 20),
          const Text('标注：', style: labelStyle),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              _buildToolChip('循环', null),
              _buildToolChip('空白', ''),
              _buildToolChip('0', '0'),
              _buildToolChip('1', '1'),
              _buildToolChip('d', 'd'),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '提示：点击格子循环 空白→0→1→d→空白；也可先选择上方标注后再点击格子。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildToolChip(String label, String? value) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedTool == value,
      onSelected: (_) {
        setState(() {
          _selectedTool = (_selectedTool == value) ? null : value;
        });
      },
    );
  }

  Widget _buildMapCard(_KmapLayout layout) {
    final colCodes = _grayCodes(layout.colBits);
    final rowCodes = _grayCodes(layout.rowBits);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [greyBoxShadow],
        gradient: whiteLinearGradient,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          border: TableBorder.all(color: Colors.blueGrey, width: 1),
          defaultColumnWidth: const FixedColumnWidth(58),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFEEF2F7)),
              children: [
                _headerCell('${layout.colVars.join()} / ${layout.rowVars.join()}'),
                for (final colCode in colCodes)
                  _headerCell(_bits(colCode, layout.colBits)),
              ],
            ),
            for (final rowCode in rowCodes)
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFEEF2F7)),
                children: [
                  _headerCell(
                    '${layout.rowVars.join()}=${_bits(rowCode, layout.rowBits)}',
                  ),
                  for (final colCode in colCodes)
                    _buildCell(layout, colCode, rowCode),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String text) {
    return Container(
      width: 58,
      height: 58,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(2),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildCell(_KmapLayout layout, int colGray, int rowGray) {
    final index = _cellIndex(layout, colGray, rowGray);
    final state = _cells[index] ?? '';

    return GestureDetector(
      onTap: () => _handleCellTap(index),
      child: Container(
        width: 58,
        height: 58,
        color: _cellColor(state),
        alignment: Alignment.center,
        child: Stack(
            fit: StackFit.expand,
          children: [
                const SizedBox.expand(),
            Center(
              child: Text(
                state.isEmpty ? '' : state,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _cellTextColor(state),
                ),
              ),
            ),
            Positioned(
              right: 3,
              bottom: 2,
              child: Text(
                '$index',
                style: const TextStyle(fontSize: 9, color: Colors.black45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _cellColor(String state) {
    switch (state) {
      case '0':
        return const Color(0xFFFFCDD2);
      case '1':
        return const Color(0xFFC8E6C9);
      case 'd':
        return const Color(0xFFFFF9C4);
      default:
        return Colors.white;
    }
  }

  Color _cellTextColor(String state) {
    switch (state) {
      case '0':
        return const Color(0xFFB71C1C);
      case '1':
        return const Color(0xFF1B5E20);
      case 'd':
        return const Color(0xFFF57F17);
      default:
        return Colors.black87;
    }
  }

  Widget _buildResultCard(List<String> order) {
    final minterms = <int>[];
    final maxterms = <int>[];
    _cells.forEach((index, state) {
      if (state == '1') minterms.add(index);
      if (state == '0') maxterms.add(index);
    });
    minterms.sort();
    maxterms.sort();

    final functionName = 'F(${order.join()})';
    final mintermsText = minterms.isEmpty ? '' : minterms.join(',');
    final maxtermsText = maxterms.isEmpty ? '' : maxterms.join(',');

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
            '表达式输出',
            style: TextStyle(
              fontFamily: 'SmileySans',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '最小项之和：$functionName = Σm($mintermsText)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
            if (minterms.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '展开：$functionName = ${_mintermsAlgebraic(minterms, order)}',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          const SizedBox(height: 6),
          Text(
            '最大项之积：$functionName = ΠM($maxtermsText)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
            if (maxterms.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '展开：$functionName = ${_maxtermsAlgebraic(maxterms, order)}',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          const SizedBox(height: 8),
          const Text(
            '注：d 为无关项，不参与最小项/最大项统计。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _KmapLayout {
  final int colBits;
  final int rowBits;
  final List<String> colVars;
  final List<String> rowVars;

  _KmapLayout({
    required this.colBits,
    required this.rowBits,
    required this.colVars,
    required this.rowVars,
  });
}
