import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Password extends StatefulWidget {
  final Color? color;
  final String? Function(String?)? validator;
  final TextStyle? labelStyle;
  final OutlineInputBorder? border;
  final InputDecoration? decoration;
  final int maxLen;
  final int minLen;
  final bool isRequired;

  final bool isLast;
  const Password({
    super.key,
    this.color,
    this.validator,
    this.labelStyle,
    this.border,
    this.decoration,
    this.isRequired = false,
    this.maxLen = 32,
    this.minLen = 8,
    this.isLast = false,
  });

  @override
  State<Password> createState() => _PasswordState();
}

class _PasswordState extends State<Password> {
  String? _errorText;
  bool _obscureText = true;
  void _validate(String value) {
    String? error;
    if (widget.isRequired && value.isEmpty) {
      error = "密码为必填项";
    } else if (widget.validator != null) {
      error = widget.validator?.call(value);
    } else if (value.length < widget.minLen) {
      error = "密码太短";
    } else if (value.length > widget.maxLen) {
      error = "密码过长";
    }
    setState(() {
      _errorText = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.isRequired
            ? Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: "*",
                      style: TextStyle(color: Colors.red),
                    ),
                    TextSpan(
                      text: "密码",
                      style:
                          widget.labelStyle ??
                          Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              )
            : Text(
                "密码",
                style:
                    widget.labelStyle ??
                    Theme.of(context).textTheme.labelMedium,
              ),
        TextField(
          keyboardType: TextInputType.visiblePassword,
          textInputAction: widget.isLast
              ? TextInputAction.done
              : TextInputAction.next,
          autocorrect: false,
          enableSuggestions: false,
          obscureText: _obscureText,
          obscuringCharacter: '•',
          decoration:
              widget.decoration ??
              InputDecoration(
                hintText: "请输入密码",
                errorText: _errorText,
                contentPadding: const EdgeInsets.only(left: 10),
                filled: true,
                fillColor:
                    widget.color ??
                    Theme.of(context).inputDecorationTheme.fillColor,
                border:
                    widget.border ??
                    Theme.of(context).inputDecorationTheme.border,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Theme.of(context).iconTheme.color?.withAlpha(135),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
              ),
          onSubmitted: _validate,
          onChanged: (value) {
            if (_errorText != null) {
              setState(() {
                _errorText = null;
              });
            }
          },
        ),
      ],
    );
  }
}

class NumberInput extends StatefulWidget {
  final String title;
  final TextStyle? labelStyle;
  final OutlineInputBorder? border;
  final Color? color;
  final InputDecoration? decoration;
  final int maxLen;
  final int minLen;
  final RegExp? pattern;
  final String? patternErrorText;
  final bool isRequired;
  final bool isLast;
  const NumberInput({
    required this.title,
    super.key,
    this.labelStyle,
    this.decoration,
    this.color,
    this.border,
    this.pattern,
    this.patternErrorText,
    this.isRequired = false,
    this.maxLen = 32,
    this.minLen = 0,
    this.isLast = false,
  });

  @override
  State<NumberInput> createState() => _NumberInputState();
}

class _NumberInputState extends State<NumberInput> {
  static final RegExp regexp = RegExp(r"^\d+$");
  String? _errorText;
  _validator(String value) {
    String? error;
    if (widget.isRequired && value.isEmpty) {
      error = "${widget.title}为必填项";
    } else if (!regexp.hasMatch(value)) {
      error = "${widget.title}必须为数字";
    } else if (!regexp.hasMatch(value)) {
      error = widget.patternErrorText ?? "格式错误";
    }
    setState(() {
      _errorText = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.isRequired
            ? Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: "*",
                      style: TextStyle(color: Colors.red),
                    ),
                    TextSpan(
                      text: widget.title,
                      style:
                          widget.labelStyle ??
                          Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              )
            : Text(
                widget.title,
                style:
                    widget.labelStyle ??
                    Theme.of(context).textTheme.labelMedium,
              ),
        TextField(
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: widget.isLast
              ? TextInputAction.done
              : TextInputAction.next,
          decoration:
              widget.decoration ??
              InputDecoration(
                hintText: "请输入${widget.title}",
                contentPadding: const EdgeInsets.only(left: 10),
                filled: true,
                fillColor:
                    widget.color ??
                    Theme.of(context).inputDecorationTheme.fillColor,
                border:
                    widget.border ??
                    Theme.of(context).inputDecorationTheme.border,
                errorText: _errorText,
              ),
          onChanged: (value) {
            if (_errorText != null) {
              setState(() {
                _errorText = null;
              });
            }
          },
          onSubmitted: _validator,
        ),
      ],
    );
  }
}

class CnNameInput extends StatefulWidget {
  final TextStyle? labelStyle;
  final OutlineInputBorder? border;
  final InputDecoration? decoration;
  final Color? color;
  final bool isRequired;

  final bool isLast;
  const CnNameInput({
    super.key,
    this.color,
    this.labelStyle,
    this.border,
    this.decoration,
    this.isRequired = false,
    this.isLast = false,
  });
  @override
  State<CnNameInput> createState() => _CnNameInputState();
}

class _CnNameInputState extends State<CnNameInput> {
  String? _errorText;
  static final RegExp regexp = RegExp(
    r"^[\u4e00-\u9fff]+(?:\u00b7[\u4e00-\u9fff]+)*$",
  );
  void _validate(String value) {
    String? error;
    if (widget.isRequired && value.isEmpty) {
      error = "姓名为必填项";
    } else if (!regexp.hasMatch(value)) {
      error = "不是合法的中文名";
    }
    setState(() {
      _errorText = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.isRequired
            ? Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: "*",
                      style: TextStyle(color: Colors.red),
                    ),
                    TextSpan(
                      text: "姓名",
                      style:
                          widget.labelStyle ??
                          Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              )
            : Text(
                "姓名",
                style:
                    widget.labelStyle ??
                    Theme.of(context).textTheme.labelMedium,
              ),
        TextField(
          keyboardType: TextInputType.text,
          textInputAction: widget.isLast
              ? TextInputAction.done
              : TextInputAction.next,
          decoration:
              widget.decoration ??
              InputDecoration(
                hintText: "请输入姓名",
                contentPadding: EdgeInsets.only(left: 10),
                filled: true,
                fillColor:
                    widget.color ??
                    Theme.of(context).inputDecorationTheme.fillColor,
                border:
                    widget.border ??
                    Theme.of(context).inputDecorationTheme.border,
                errorText: _errorText,
              ),
          onSubmitted: _validate,
          onChanged: (value) {
            if (_errorText != null) {
              setState(() {
                _errorText = null;
              });
            }
          },
        ),
      ],
    );
  }
}
