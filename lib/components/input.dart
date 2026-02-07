import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Input extends StatefulWidget {
  final Color? color;
  final String? Function(String?)? validator;
  final TextStyle? labelStyle;
  final OutlineInputBorder? border;
  final InputDecoration? decoration;
  final String title;
  final int maxLen;
  final int minLen;
  final RegExp? pattern;
  final String? patternErrorText;
  final bool isRequired;
  final bool isLast;
  final TextInputType keyboardType;
  final bool autocorrect;
  final bool isPassword;
  final List<TextInputFormatter>? inputFormatters;
  const Input({
    super.key,
    this.color,
    this.validator,
    this.labelStyle,
    this.border,
    this.decoration,
    this.isRequired = false,
    this.isLast = false,
    this.autocorrect = false,
    this.isPassword = false,
    this.pattern,
    this.patternErrorText,
    this.maxLen = 100,
    this.minLen = 1,
    this.keyboardType = TextInputType.text,
    required this.title,
    this.inputFormatters,
  });
  @override
  State<Input> createState() => _InputState();

  factory Input.password({
    Key? key,
    bool isRequired = false,
    int minLen = 8,
    int maxLen = 32,
    String? Function(String?)? validator,
    TextStyle? labelStyle,
    Color? color,
    OutlineInputBorder? border,
    InputDecoration? decoration,
    bool isLast = false,
  }) {
    return Input(
      key: key,
      title: '密码',
      isPassword: true,
      isRequired: isRequired,
      minLen: minLen,
      maxLen: maxLen,
      validator: validator,
      keyboardType: TextInputType.visiblePassword,
      autocorrect: false,
      isLast: isLast,
      labelStyle: labelStyle,
      color: color,
      border: border,
      decoration: decoration,
    );
  }

  factory Input.cnName({
    Key? key,
    bool isRequired = false,
    TextStyle? labelStyle,
    Color? color,
    OutlineInputBorder? border,
    InputDecoration? decoration,
    bool isLast = false,
  }) {
    return Input(
      key: key,
      title: '姓名',
      isRequired: isRequired,
      pattern: RegExp(r"^[\u4e00-\u9fff]+(?:\u00b7[\u4e00-\u9fff]+)*$"),
      patternErrorText: '不是合法的中文名',
      isLast: isLast,
      labelStyle: labelStyle,
      color: color,
      border: border,
      decoration: decoration,
    );
  }

  factory Input.number({
    Key? key,
    required String title,
    bool isRequired = false,
    int minLen = 1,
    int maxLen = 32,
    String? patternErrorText,
    TextStyle? labelStyle,
    Color? color,
    OutlineInputBorder? border,
    InputDecoration? decoration,
    bool isLast = false,
  }) {
    return Input(
      key: key,
      title: title,
      isRequired: isRequired,
      minLen: minLen,
      maxLen: maxLen,
      pattern: RegExp(r'^\d+$'),
      patternErrorText: patternErrorText ?? '$title必须为数字',
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      isLast: isLast,
      labelStyle: labelStyle,
      color: color,
      border: border,
      decoration: decoration,
    );
  }
}

class _InputState extends State<Input> {
  String? _errorText;
  // ignore: prefer_final_fields
  bool _obscureText = false;
  @override
  void initState() {
    super.initState();
    setState(() {
      _obscureText = widget.isPassword;
    });
  }

  void _validate(String value) {
    String? error;
    if (widget.isRequired && value.isEmpty) {
      error = "${widget.title}为必填项";
    } else if (widget.validator != null) {
      error = widget.validator?.call(value) ?? "非法输入";
    } else if (widget.pattern != null && !widget.pattern!.hasMatch(value)) {
      error = widget.patternErrorText ?? '格式不正确';
    } else if (value.length < widget.minLen) {
      error = "${widget.title}太短";
    } else if (value.length > widget.maxLen) {
      error = "${widget.title}过长";
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
          keyboardType: widget.keyboardType,
          textInputAction: widget.isLast
              ? TextInputAction.done
              : TextInputAction.next,
          autocorrect: widget.autocorrect,
          inputFormatters: widget.inputFormatters,
          obscureText: _obscureText,
          decoration:
              widget.decoration ??
              InputDecoration(
                hintText: "请输入${widget.title}",
                errorText: _errorText,
                contentPadding: const EdgeInsets.only(left: 10),
                filled: true,
                fillColor:
                    widget.color ??
                    Theme.of(context).inputDecorationTheme.fillColor,
                border:
                    widget.border ??
                    Theme.of(context).inputDecorationTheme.border,
                suffixIcon: widget.isPassword
                    ? IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Theme.of(
                            context,
                          ).iconTheme.color?.withAlpha(135),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      )
                    : null,
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