import 'package:flutter/material.dart';
import 'package:shine/components/line.dart';
import 'package:shine/theme.dart';

class ToolFunctionTransformerPage extends StatefulWidget {
  const ToolFunctionTransformerPage({super.key});

  @override
  State<ToolFunctionTransformerPage> createState() =>
      _ToolFunctionTransformerPageState();
}

class _ToolFunctionTransformerPageState extends State<ToolFunctionTransformerPage> {
  String _selectedName = _entries.first.name;
  final TextEditingController _inputController = TextEditingController();
  _TransformEntry? _computedResult;
  String? _computedError;

  _TransformEntry get _selected =>
      _entries.firstWhere((e) => e.name == _selectedName);

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('函数变换器', style: titleTextStyle),
        centerTitle: true,
        bottom: bottomLine,
      ),
      body: SafeArea(
        child: ListView(
          padding: bodyPadding,
          children: [
              _buildInputCard(),
              if (_computedError != null) ...[
                const SizedBox(height: 12),
                _buildErrorCard(_computedError!),
              ],
              if (_computedResult != null) ...[
                const SizedBox(height: 12),
                _buildTransformCard(_computedResult!),
              ],
              const SizedBox(height: 12),
            _buildSelectorCard(),
            const SizedBox(height: 12),
            _buildTransformCard(_selected),
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
          const Text('输入函数表达式', style: labelStyle),
          const SizedBox(height: 8),
          TextField(
            controller: _inputController,
            decoration: const InputDecoration(
              hintText: '例如：sin(2*t)*u(t) 或 a^n*u[n]',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onSubmitted: (_) {
                _calculate();
              },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(
                onPressed: _calculate,
                child: const Text('计算变换'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _inputController.clear();
                    _computedResult = null;
                    _computedError = null;
                  });
                },
                child: const Text('清空'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '支持：δ(t), u(t), t, t^n, e^(a*t), sin(w*t), cos(w*t), rect(t/T), '
            'δ[n], u[n], a^n, n, sin(w*n), cos(w*n) 等；也支持常用组合。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [greyBoxShadow],
        gradient: whiteLinearGradient,
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.red, fontSize: 14),
      ),
    );
  }

  void _calculate() {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _computedError = '请输入函数表达式';
        _computedResult = null;
      });
      return;
    }
    final result = _matchInput(input);
    setState(() {
      if (result == null) {
        _computedError = '暂不支持该输入，请参考下方支持列表或选择常用函数。';
        _computedResult = null;
      } else {
        _computedError = null;
        _computedResult = result;
      }
    });
  }

  _TransformEntry? _matchInput(String raw) {
    final x = _normalize(raw);
    if (x.startsWith('-')) {
      final base = _matchInput(x.substring(1));
      if (base != null) {
        return _scaled(base, '-1');
      }
    }
    if (x.startsWith('+')) {
      final base = _matchInput(x.substring(1));
      if (base != null) {
        return base;
      }
    }
    final coefMatch = RegExp(r'^([0-9.]+)\*?(.*)$').firstMatch(x);
    if (coefMatch != null) {
      final coef = coefMatch.group(1)!;
      final rest = coefMatch.group(2)!;
      if (rest.isNotEmpty && rest != x) {
        final base = _matchNormalized(rest);
        if (base != null) {
          return _scaled(base, coef);
        }
      }
    }
    return _matchNormalized(x);
  }

  _TransformEntry? _matchNormalized(String x) {
    if (x.contains('[n]')) {
      return _matchDiscrete(x);
    }
    return _matchContinuous(x);
  }

  _TransformEntry _scaled(_TransformEntry base, String coef) {
    return _TransformEntry(
      name: '$coef·${base.name}',
      category: base.category,
      timeDomain: '$coef·${base.timeDomain}',
      fourier: _scaleFormula(base.fourier, coef),
      laplace: _scaleFormula(base.laplace, coef),
      zTransform: _scaleFormula(base.zTransform, coef),
      note: base.note,
    );
  }

  String _scaleFormula(String formula, String coef) {
    if (formula.startsWith('不适用')) {
      return formula;
    }
    final eq = formula.indexOf('=');
    if (eq >= 0) {
      return '${formula.substring(0, eq + 1)} $coef·(${formula.substring(eq + 1).trim()})';
    }
    final colon = formula.indexOf(':');
    if (colon >= 0) {
      return '${formula.substring(0, colon + 1)} $coef·(${formula.substring(colon + 1).trim()})';
    }
    return '$coef·($formula)';
  }

  String _normalize(String s) {
    var x = s.replaceAll('T', '\u0001');
    x = x.toLowerCase();
    x = x.replaceAll('\u0001', 'T');
    x = x.replaceAll(' ', '');
    x = x.replaceAll('**', '^');
    x = x.replaceAll('×', '*');
    x = x.replaceAll('·', '*');
    return x;
  }

  _TransformEntry? _matchDiscrete(String x) {
    if (x == 'δ[n]' || x == 'dirac[n]' || x == 'impulse[n]' || x == 'delta[n]') {
      return _TransformEntry(
        name: 'δ[n]',
        category: '离散',
        timeDomain: 'δ[n]',
        fourier: 'DTFT = 1',
        laplace: '不适用（离散信号）',
        zTransform: 'F(z) = 1',
      );
    }
    if (x == 'u[n]' || x == 'step[n]' || x == 'heaviside[n]') {
      return _TransformEntry(
        name: 'u[n]',
        category: '离散',
        timeDomain: 'u[n]',
        fourier: 'DTFT = 1/(1 - e^(-jω)) + π·Σ_{k} δ(ω - 2πk)',
        laplace: '不适用（离散信号）',
        zTransform: 'F(z) = z/(z - 1),  |z| > 1',
      );
    }
    final aNU = RegExp(r'^([a-z0-9.]+)\^n\*?u\[n\]$').firstMatch(x);
    if (aNU != null) {
      final a = aNU.group(1)!;
      return _TransformEntry(
        name: '$a^n·u[n]',
        category: '离散',
        timeDomain: '$a^n·u[n]',
        fourier: 'DTFT = 1/(1 - $a·e^(-jω)),  |$a| < 1',
        laplace: '不适用（离散信号）',
        zTransform: 'F(z) = z/(z - $a),  |z| > |$a|',
      );
    }
    if (x == 'n*u[n]' || x == 'nu[n]') {
      return _TransformEntry(
        name: 'n·u[n]',
        category: '离散',
        timeDomain: 'n·u[n]',
        fourier: 'DTFT = e^(-jω)/(1 - e^(-jω))²',
        laplace: '不适用（离散信号）',
        zTransform: 'F(z) = z/(z - 1)²,  |z| > 1',
      );
    }
    final naNU = RegExp(r'^n\*?([a-z0-9.]+)\^n\*?u\[n\]$').firstMatch(x);
    if (naNU != null) {
      final a = naNU.group(1)!;
      return _TransformEntry(
        name: 'n·$a^n·u[n]',
        category: '离散',
        timeDomain: 'n·$a^n·u[n]',
        fourier: 'DTFT = $a·e^(-jω)/(1 - $a·e^(-jω))²',
        laplace: '不适用（离散信号）',
        zTransform: 'F(z) = $a·z/(z - $a)²,  |z| > |$a|',
      );
    }
    final sinN = RegExp(r'^sin\(([a-z0-9.]+)\*?n\)\*?u\[n\]$').firstMatch(x);
    if (sinN != null) {
      final w = sinN.group(1)!;
      return _TransformEntry(
        name: 'sin($w·n)·u[n]',
        category: '离散',
        timeDomain: 'sin($w·n)·u[n]',
        fourier: 'DTFT = sin($w)·e^(-jω)/(1 - 2cos($w)·e^(-jω) + e^(-j2ω))',
        laplace: '不适用（离散信号）',
        zTransform: 'F(z) = z·sin($w)/(z² - 2z·cos($w) + 1)',
      );
    }
    final cosN = RegExp(r'^cos\(([a-z0-9.]+)\*?n\)\*?u\[n\]$').firstMatch(x);
    if (cosN != null) {
      final w = cosN.group(1)!;
      return _TransformEntry(
        name: 'cos($w·n)·u[n]',
        category: '离散',
        timeDomain: 'cos($w·n)·u[n]',
        fourier: 'DTFT = (1 - cos($w)·e^(-jω))/(1 - 2cos($w)·e^(-jω) + e^(-j2ω))',
        laplace: '不适用（离散信号）',
        zTransform: 'F(z) = z(z - cos($w))/(z² - 2z·cos($w) + 1)',
      );
    }
    final aSinN = RegExp(r'^([a-z0-9.]+)\^n\*?sin\(([a-z0-9.]+)\*?n\)\*?u\[n\]$').firstMatch(x);
    if (aSinN != null) {
      final a = aSinN.group(1)!;
      final w = aSinN.group(2)!;
      return _TransformEntry(
        name: '$a^n·sin($w·n)·u[n]',
        category: '离散',
        timeDomain: '$a^n·sin($w·n)·u[n]',
        fourier: 'DTFT = $a·sin($w)·e^(-jω)/(1 - 2·$a·cos($w)·e^(-jω) + $a²·e^(-j2ω))',
        laplace: '不适用（离散信号）',
        zTransform: 'F(z) = $a·z·sin($w)/(z² - 2·$a·z·cos($w) + $a²)',
        note: '收敛域 |z| > |$a|',
      );
    }
    final aCosN = RegExp(r'^([a-z0-9.]+)\^n\*?cos\(([a-z0-9.]+)\*?n\)\*?u\[n\]$').firstMatch(x);
    if (aCosN != null) {
      final a = aCosN.group(1)!;
      final w = aCosN.group(2)!;
      return _TransformEntry(
        name: '$a^n·cos($w·n)·u[n]',
        category: '离散',
        timeDomain: '$a^n·cos($w·n)·u[n]',
        fourier: 'DTFT = (1 - $a·cos($w)·e^(-jω))/(1 - 2·$a·cos($w)·e^(-jω) + $a²·e^(-j2ω))',
        laplace: '不适用（离散信号）',
        zTransform: 'F(z) = z(z - $a·cos($w))/(z² - 2·$a·z·cos($w) + $a²)',
        note: '收敛域 |z| > |$a|',
      );
    }
    return null;
  }

  _TransformEntry? _matchContinuous(String x) {
    if (x == 'δ(t)' || x == 'dirac(t)' || x == 'impulse(t)' || x == 'delta(t)') {
      return _TransformEntry(
        name: 'δ(t)',
        category: '连续',
        timeDomain: 'δ(t)',
        fourier: 'F(jω) = 1',
        laplace: 'F(s) = 1',
        zTransform: '不适用（连续信号）',
      );
    }
    final diracShift = RegExp(r'^(?:δ|dirac|impulse|delta)\(t-([0-9.]+)\)$').firstMatch(x);
    if (diracShift != null) {
      final t0 = diracShift.group(1)!;
      return _TransformEntry(
        name: 'δ(t-$t0)',
        category: '连续',
        timeDomain: 'δ(t-$t0)',
        fourier: 'F(jω) = e^(-jω·$t0)',
        laplace: 'F(s) = e^(-s·$t0)',
        zTransform: '不适用（连续信号）',
        note: '时移性质',
      );
    }
    if (x == 'u(t)' || x == 'step(t)' || x == 'heaviside(t)') {
      return _TransformEntry(
        name: 'u(t)',
        category: '连续',
        timeDomain: 'u(t)',
        fourier: 'F(jω) = πδ(ω) + 1/(jω)',
        laplace: 'F(s) = 1/s',
        zTransform: '不适用（连续信号）',
        note: '收敛域 Re(s) > 0',
      );
    }
    final uShift = RegExp(r'^(?:u|step|heaviside)\(t-([0-9.]+)\)$').firstMatch(x);
    if (uShift != null) {
      final t0 = uShift.group(1)!;
      return _TransformEntry(
        name: 'u(t-$t0)',
        category: '连续',
        timeDomain: 'u(t-$t0)',
        fourier: 'F(jω) = e^(-jω·$t0)·(πδ(ω) + 1/(jω))',
        laplace: 'F(s) = e^(-s·$t0)/s',
        zTransform: '不适用（连续信号）',
        note: '时移性质',
      );
    }
    if (x == 't*u(t)' || x == 'tu(t)' || x == 'ramp(t)') {
      return _TransformEntry(
        name: 't·u(t)',
        category: '连续',
        timeDomain: 't·u(t)',
        fourier: 'F(jω) = jπδ\'(ω) - 1/ω²',
        laplace: 'F(s) = 1/s²',
        zTransform: '不适用（连续信号）',
      );
    }
    final tPow = RegExp(r'^t\^(\d+)\*?u\(t\)$').firstMatch(x);
    if (tPow != null) {
      final n = tPow.group(1)!;
      return _TransformEntry(
        name: 't^$n·u(t)',
        category: '连续',
        timeDomain: 't^$n·u(t)',
        fourier: 'F(jω) = ${_factorial(int.parse(n))}/(jω)^${int.parse(n) + 1}（含冲激项）',
        laplace: 'F(s) = ${_factorial(int.parse(n))}/s^${int.parse(n) + 1}',
        zTransform: '不适用（连续信号）',
      );
    }
    final exp = RegExp(r'^e\^\(([a-z0-9.+-]+)\*?t\)\*?u\(t\)$').firstMatch(x);
    if (exp != null) {
      final a = exp.group(1)!;
      return _TransformEntry(
        name: 'e^($a·t)·u(t)',
        category: '连续',
        timeDomain: 'e^($a·t)·u(t)',
        fourier: 'F(jω) = 1/(jω ${_signedDenominator(a)})',
        laplace: 'F(s) = 1/(s ${_signedDenominator(a)})',
        zTransform: '不适用（连续信号）',
        note: '收敛域 Re(s) > $a',
      );
    }
    final sinT = RegExp(r'^sin\(([a-z0-9.]+)\*?t\)\*?u\(t\)$').firstMatch(x);
    if (sinT != null) {
      final w = sinT.group(1)!;
      return _TransformEntry(
        name: 'sin($w·t)·u(t)',
        category: '连续',
        timeDomain: 'sin($w·t)·u(t)',
        fourier: 'F(jω) = $w/($w² - ω²) + (jπ/2)[δ(ω+$w) - δ(ω-$w)]',
        laplace: 'F(s) = $w/(s² + $w²)',
        zTransform: '不适用（连续信号）',
      );
    }
    final cosT = RegExp(r'^cos\(([a-z0-9.]+)\*?t\)\*?u\(t\)$').firstMatch(x);
    if (cosT != null) {
      final w = cosT.group(1)!;
      return _TransformEntry(
        name: 'cos($w·t)·u(t)',
        category: '连续',
        timeDomain: 'cos($w·t)·u(t)',
        fourier: 'F(jω) = jω/($w² - ω²) + (π/2)[δ(ω-$w) + δ(ω+$w)]',
        laplace: 'F(s) = s/(s² + $w²)',
        zTransform: '不适用（连续信号）',
      );
    }
    final expSin = RegExp(r'^e\^\(([a-z0-9.+-]+)\*?t\)\*?sin\(([a-z0-9.]+)\*?t\)\*?u\(t\)$').firstMatch(x);
    if (expSin != null) {
      final a = expSin.group(1)!;
      final w = expSin.group(2)!;
      return _TransformEntry(
        name: 'e^($a·t)·sin($w·t)·u(t)',
        category: '连续',
        timeDomain: 'e^($a·t)·sin($w·t)·u(t)',
        fourier: 'F(jω) = $w/((jω ${_signedDenominator(a)})² + $w²)',
        laplace: 'F(s) = $w/((s ${_signedDenominator(a)})² + $w²)',
        zTransform: '不适用（连续信号）',
        note: '收敛域 Re(s) > $a',
      );
    }
    final expCos = RegExp(r'^e\^\(([a-z0-9.+-]+)\*?t\)\*?cos\(([a-z0-9.]+)\*?t\)\*?u\(t\)$').firstMatch(x);
    if (expCos != null) {
      final a = expCos.group(1)!;
      final w = expCos.group(2)!;
      return _TransformEntry(
        name: 'e^($a·t)·cos($w·t)·u(t)',
        category: '连续',
        timeDomain: 'e^($a·t)·cos($w·t)·u(t)',
        fourier: 'F(jω) = (jω ${_signedDenominator(a)})/((jω ${_signedDenominator(a)})² + $w²)',
        laplace: 'F(s) = (s ${_signedDenominator(a)})/((s ${_signedDenominator(a)})² + $w²)',
        zTransform: '不适用（连续信号）',
        note: '收敛域 Re(s) > $a',
      );
    }
    final tPowExp = RegExp(r'^t\^(\d+)\*?e\^\(([a-z0-9.+-]+)\*?t\)\*?u\(t\)$').firstMatch(x);
    if (tPowExp != null) {
      final n = tPowExp.group(1)!;
      final a = tPowExp.group(2)!;
      return _TransformEntry(
        name: 't^$n·e^($a·t)·u(t)',
        category: '连续',
        timeDomain: 't^$n·e^($a·t)·u(t)',
        fourier: 'F(jω) = ${_factorial(int.parse(n))}/(jω ${_signedDenominator(a)})^${int.parse(n) + 1}',
        laplace: 'F(s) = ${_factorial(int.parse(n))}/(s ${_signedDenominator(a)})^${int.parse(n) + 1}',
        zTransform: '不适用（连续信号）',
        note: '收敛域 Re(s) > $a',
      );
    }
    final rect = RegExp(r'^rect\(t(?:/([a-zA-Z0-9.]+))?\)$').firstMatch(x);
    if (rect != null) {
      final t = rect.group(1);
      final tStr = t ?? '1';
      return _TransformEntry(
        name: t == null ? 'rect(t)' : 'rect(t/$tStr)',
        category: '连续',
        timeDomain: t == null ? 'rect(t)' : 'rect(t/$tStr)',
        fourier: tStr == '1'
              ? 'F(jω) = Sa(ω/2)'
              : 'F(jω) = $tStr·Sa(ω·$tStr/2)',
        laplace: tStr == '1'
              ? 'F(s) = (e^(s/2) - e^(-s/2))/s'
              : 'F(s) = (e^(s$tStr/2) - e^(-s$tStr/2))/s',
        zTransform: '不适用（连续信号）',
      );
    }
    if (x == 'sinc(t)' || x == 'sa(t)') {
      return _TransformEntry(
        name: 'Sa(t)',
        category: '连续',
        timeDomain: 'Sa(t) = sin(t)/t',
        fourier: 'F(jω) = π·rect(ω/2)',
        laplace: '不适用（常用双边形式）',
        zTransform: '不适用（连续信号）',
      );
    }
    if (x == 'e^(-t^2)' || x == 'e^(-t²)' || x == 'gaussian(t)' || x == 'exp(-t^2)' || x == 'exp(-t²)') {
      return _TransformEntry(
        name: 'e^(-t²)',
        category: '连续',
        timeDomain: 'e^(-t²)',
        fourier: 'F(jω) = √π·e^(-ω²/4)',
        laplace: '不适用（常用双边形式）',
        zTransform: '不适用（连续信号）',
      );
    }
    return null;
  }

  int _factorial(int n) {
    var result = 1;
    for (var i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
  }

  String _signedDenominator(String a) {
    if (a.startsWith('-')) {
      return '+${a.substring(1)}';
    }
    if (a.startsWith('+')) {
      return '-${a.substring(1)}';
    }
    return '-$a';
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
          const Text('选择函数', style: labelStyle),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: _selectedName,
            isExpanded: true,
            items: [
              for (final entry in _entries)
                DropdownMenuItem(
                  value: entry.name,
                  child: Text(
                    '${entry.category} · ${entry.name}',
                    maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedName = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransformCard(_TransformEntry entry) {
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
            entry.name,
            style: const TextStyle(
              fontFamily: 'SmileySans',
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Divider(height: 20),
          _buildRow(
            entry.category == '离散' ? '序列 f[n]' : '时域 f(t)',
            entry.timeDomain,
          ),
          _buildRow(
            entry.category == '离散'
                ? (entry.fourier.startsWith('DFT')
                    ? '离散傅里叶变换 DFT'
                    : '离散时间傅里叶变换 DTFT')
                : '傅里叶变换 F(jω)',
            entry.fourier,
          ),
          _buildRow(
            '拉普拉斯变换 F(s)',
            entry.laplace,
          ),
          _buildRow(
            'z变换 F(z)',
            entry.zTransform,
          ),
          if (entry.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '备注：${entry.note}',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 8),
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
        '说明：本工具面向电子、通信专业学生，支持输入常见函数并查看其傅里叶变换、'
        '拉普拉斯变换和 z 变换。离散信号默认给出 DTFT 与 z 变换；'
        '连续信号默认给出傅里叶变换与拉普拉斯变换。',
        style: TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
      ),
    );
  }
}

class _TransformEntry {
  final String name;
  final String category;
  final String timeDomain;
  final String fourier;
  final String laplace;
  final String zTransform;
  final String note;

  const _TransformEntry({
    required this.name,
    required this.category,
    required this.timeDomain,
    required this.fourier,
    required this.laplace,
    required this.zTransform,
    this.note = '',
  });
}

const List<_TransformEntry> _entries = [
  // ---------------- 连续信号 ----------------
  _TransformEntry(
    name: '单位冲激 δ(t)',
    category: '连续',
    timeDomain: 'δ(t)',
    fourier: 'F(jω) = 1',
    laplace: 'F(s) = 1',
    zTransform: '不适用（连续信号）',
    note: '冲激函数的取样性：∫ δ(t) dt = 1',
  ),
  _TransformEntry(
    name: '单位阶跃 u(t)',
    category: '连续',
    timeDomain: 'u(t)',
    fourier: 'F(jω) = πδ(ω) + 1/(jω)',
    laplace: 'F(s) = 1/s',
    zTransform: '不适用（连续信号）',
    note: '单边拉普拉斯收敛域 Re(s) > 0',
  ),
  _TransformEntry(
    name: '单位斜坡 t·u(t)',
    category: '连续',
    timeDomain: 't·u(t)',
    fourier: 'F(jω) = jπδ\'(ω) - 1/ω²',
    laplace: 'F(s) = 1/s²',
    zTransform: '不适用（连续信号）',
  ),
  _TransformEntry(
    name: '指数衰减 e^(-at)·u(t)',
    category: '连续',
    timeDomain: 'e^(-at)·u(t),  a > 0',
    fourier: 'F(jω) = 1/(a + jω)',
    laplace: 'F(s) = 1/(s + a)',
    zTransform: '不适用（连续信号）',
    note: '收敛域 Re(s) > -a',
  ),
  _TransformEntry(
    name: '正弦 sin(ω0·t)·u(t)',
    category: '连续',
    timeDomain: 'sin(ω0·t)·u(t)',
    fourier: 'F(jω) = ω0/(ω0² - ω²) + (jπ/2)[δ(ω+ω0) - δ(ω-ω0)]',
    laplace: 'F(s) = ω0/(s² + ω0²)',
    zTransform: '不适用（连续信号）',
    note: '拉普拉斯收敛域 Re(s) > 0',
  ),
  _TransformEntry(
    name: '余弦 cos(ω0·t)·u(t)',
    category: '连续',
    timeDomain: 'cos(ω0·t)·u(t)',
    fourier: 'F(jω) = jω/(ω0² - ω²) + (π/2)[δ(ω-ω0) + δ(ω+ω0)]',
    laplace: 'F(s) = s/(s² + ω0²)',
    zTransform: '不适用（连续信号）',
    note: '拉普拉斯收敛域 Re(s) > 0',
  ),
  _TransformEntry(
    name: '矩形脉冲 rect(t/T)',
    category: '连续',
    timeDomain: 'rect(t/T) = 1, |t| < T/2',
    fourier: 'F(jω) = T·Sa(ωT/2) = T·sinc(ωT/(2π))',
    laplace: 'F(s) = (e^(sT/2) - e^(-sT/2))/s',
    zTransform: '不适用（连续信号）',
  ),
  _TransformEntry(
    name: '抽样函数 Sa(t)',
    category: '连续',
    timeDomain: 'Sa(t) = sin(t)/t',
    fourier: 'F(jω) = π·rect(ω/2)',
    laplace: '不适用（常用双边形式）',
    zTransform: '不适用（连续信号）',
  ),
  _TransformEntry(
    name: '衰减正弦 e^(-at)·sin(ω0·t)·u(t)',
    category: '连续',
    timeDomain: 'e^(-at)·sin(ω0·t)·u(t),  a > 0',
    fourier: 'F(jω) = ω0/((a + jω)² + ω0²)',
    laplace: 'F(s) = ω0/((s + a)² + ω0²)',
    zTransform: '不适用（连续信号）',
    note: '收敛域 Re(s) > -a',
  ),
  _TransformEntry(
    name: '衰减余弦 e^(-at)·cos(ω0·t)·u(t)',
    category: '连续',
    timeDomain: 'e^(-at)·cos(ω0·t)·u(t),  a > 0',
    fourier: 'F(jω) = (a + jω)/((a + jω)² + ω0²)',
    laplace: 'F(s) = (s + a)/((s + a)² + ω0²)',
    zTransform: '不适用（连续信号）',
    note: '收敛域 Re(s) > -a',
  ),
  _TransformEntry(
    name: '高斯函数 e^(-t²)',
    category: '连续',
    timeDomain: 'e^(-t²)',
    fourier: 'F(jω) = √π·e^(-ω²/4)',
    laplace: '不适用（常用双边形式）',
    zTransform: '不适用（连续信号）',
  ),
  _TransformEntry(
    name: '冲激串 ∑δ(t - nT)',
    category: '连续',
    timeDomain: 'p(t) = Σ_{n=-∞}^{∞} δ(t - nT)',
    fourier: 'F(jω) = ω0·Σ_{k=-∞}^{∞} δ(ω - kω0),  ω0 = 2π/T',
    laplace: '不适用（常用双边形式）',
    zTransform: '不适用（连续信号）',
    note: '用于采样定理分析',
  ),

  // ---------------- 离散信号 ----------------
  _TransformEntry(
    name: '单位脉冲 δ[n]',
    category: '离散',
    timeDomain: 'δ[n]',
    fourier: 'DTFT = 1',
    laplace: '不适用（离散信号）',
    zTransform: 'F(z) = 1',
  ),
  _TransformEntry(
    name: '单位阶跃 u[n]',
    category: '离散',
    timeDomain: 'u[n]',
    fourier: 'DTFT = 1/(1 - e^(-jω)) + π·Σ_{k} δ(ω - 2πk)',
    laplace: '不适用（离散信号）',
    zTransform: 'F(z) = z/(z - 1),  |z| > 1',
  ),
  _TransformEntry(
    name: '指数序列 a^n·u[n]',
    category: '离散',
    timeDomain: 'a^n·u[n]',
    fourier: 'DTFT = 1/(1 - a·e^(-jω)),  |a| < 1',
    laplace: '不适用（离散信号）',
    zTransform: 'F(z) = z/(z - a),  |z| > |a|',
  ),
  _TransformEntry(
    name: '斜坡序列 n·u[n]',
    category: '离散',
    timeDomain: 'n·u[n]',
    fourier: 'DTFT = e^(-jω)/(1 - e^(-jω))²',
    laplace: '不适用（离散信号）',
    zTransform: 'F(z) = z/(z - 1)²,  |z| > 1',
  ),
  _TransformEntry(
    name: '正弦序列 sin(ω0·n)·u[n]',
    category: '离散',
    timeDomain: 'sin(ω0·n)·u[n]',
    fourier: 'DTFT = sin(ω0)·e^(-jω)/(1 - 2cos(ω0)·e^(-jω) + e^(-j2ω))',
    laplace: '不适用（离散信号）',
    zTransform: 'F(z) = z·sin(ω0)/(z² - 2z·cos(ω0) + 1)',
  ),
  _TransformEntry(
    name: '余弦序列 cos(ω0·n)·u[n]',
    category: '离散',
    timeDomain: 'cos(ω0·n)·u[n]',
    fourier: 'DTFT = (1 - cos(ω0)·e^(-jω))/(1 - 2cos(ω0)·e^(-jω) + e^(-j2ω))',
    laplace: '不适用（离散信号）',
    zTransform: 'F(z) = z(z - cos(ω0))/(z² - 2z·cos(ω0) + 1)',
  ),
  _TransformEntry(
    name: '衰减正弦 a^n·sin(ω0·n)·u[n]',
    category: '离散',
    timeDomain: 'a^n·sin(ω0·n)·u[n]',
    fourier: 'DTFT = a·sin(ω0)·e^(-jω)/(1 - 2a·cos(ω0)·e^(-jω) + a²·e^(-j2ω))',
    laplace: '不适用（离散信号）',
    zTransform: 'F(z) = a·z·sin(ω0)/(z² - 2a·z·cos(ω0) + a²)',
    note: '收敛域 |z| > |a|',
  ),
  _TransformEntry(
    name: '矩形脉冲序列（N点）',
    category: '离散',
    timeDomain: 'x[n] = 1,  0 ≤ n ≤ N-1',
    fourier: 'DTFT = e^(-jω(N-1)/2)·sin(ωN/2)/sin(ω/2)',
    laplace: '不适用（离散信号）',
    zTransform: 'F(z) = (1 - z^(-N))/(1 - z^(-1))',
  ),
  _TransformEntry(
    name: 'N点有限长序列 DFT',
    category: '离散',
    timeDomain: 'x[n],  n = 0, 1, ..., N-1',
    fourier: 'DFT: X[k] = Σ_{n=0}^{N-1} x[n]·e^(-j2πkn/N)',
    laplace: '不适用（离散信号）',
    zTransform: 'X(z) = Σ_{n=0}^{N-1} x[n]·z^(-n)',
    note: 'DFT 是 DTFT 在单位圆上的等间隔采样',
  ),
];
