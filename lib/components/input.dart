import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Input extends StatefulWidget {
  static final TextInputFormatter _textInputFormatterNoEmptyCharacter =
      FilteringTextInputFormatter.deny(RegExp(r"\s"));
  static final TextInputFormatter _textInputFormatterAllowCnNameCharacter =
      FilteringTextInputFormatter.allow(RegExp(r"[\u4e00-\u9fff\u00b7]"));
  final String label;
  final String name;
  final Color? color;
  final String? Function(String?)? validator;
  final TextStyle? labelStyle;
  final OutlineInputBorder? border;
  final InputDecoration? decoration;
  final int maxLength;
  final int minLength;
  final RegExp? pattern;
  final String? patternErrorText;
  final bool isRequired;
  final bool isLast;
  final TextInputType keyboardType;
  final bool autocorrect;
  final bool isPassword;
  final List<TextInputFormatter>? inputFormatters;
  final AutovalidateMode? autovalidateMode;
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
    this.maxLength = 100,
    this.minLength = 1,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    required this.label,
    required this.name,
    this.autovalidateMode,
  });
  @override
  State<Input> createState() => _InputState();

  factory Input.password({
    Key? key,
    String label = '密码',
    String name = 'password',
    bool isRequired = false,
    int minLength = 8,
    int maxLength = 32,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextStyle? labelStyle,
    Color? color,
    OutlineInputBorder? border,
    InputDecoration? decoration,
    bool isLast = false,
    AutovalidateMode autovalidateMode = AutovalidateMode.onUserInteraction,
  }) {
    return Input(
      key: key,
      label: label,
      name: name,
      isPassword: true,
      isRequired: isRequired,
      minLength: minLength,
      maxLength: maxLength,
      validator: validator,
      keyboardType: TextInputType.visiblePassword,
      inputFormatters: inputFormatters ?? [_textInputFormatterNoEmptyCharacter],
      autocorrect: false,
      isLast: isLast,
      labelStyle: labelStyle,
      color: color,
      border: border,
      decoration: decoration,
      autovalidateMode: autovalidateMode,
    );
  }

  factory Input.cnName({
    Key? key,
    String label = '姓名',
    String name = 'cnName',
    bool isRequired = false,
    TextStyle? labelStyle,
    Color? color,
    OutlineInputBorder? border,
    InputDecoration? decoration,
    bool isLast = false,
    List<TextInputFormatter>? inputFormatters,
    AutovalidateMode autovalidateMode = AutovalidateMode.onUserInteraction,
  }) {
    return Input(
      key: key,
      label: label,
      name: name,
      isRequired: isRequired,
      pattern: RegExp(r"^[\u4e00-\u9fff]+(?:\u00b7[\u4e00-\u9fff]+)*$"),
      patternErrorText: '不是合法的中文名',
      inputFormatters:
          inputFormatters ?? [_textInputFormatterAllowCnNameCharacter],
      isLast: isLast,
      labelStyle: labelStyle,
      color: color,
      border: border,
      decoration: decoration,
      autovalidateMode: autovalidateMode,
    );
  }

  factory Input.number({
    Key? key,
    String label = '编号',
    String name = 'number',
    bool isRequired = false,
    int minLength = 1,
    int maxLength = 32,
    String? patternErrorText,
    TextStyle? labelStyle,
    Color? color,
    OutlineInputBorder? border,
    List<TextInputFormatter>? inputFormatters,
    InputDecoration? decoration,
    bool isLast = false,
    AutovalidateMode autovalidateMode = AutovalidateMode.onUserInteraction,
  }) {
    return Input(
      key: key,
      label: label,
      name: name,
      isRequired: isRequired,
      minLength: minLength,
      maxLength: maxLength,
      pattern: RegExp(r'^\d+$'),
      patternErrorText: patternErrorText ?? '$label必须为数字',
      keyboardType: TextInputType.number,
      inputFormatters:
          inputFormatters ?? [FilteringTextInputFormatter.digitsOnly],
      isLast: isLast,
      labelStyle: labelStyle,
      color: color,
      border: border,
      decoration: decoration,
      autovalidateMode: autovalidateMode,
    );
  }
}

class _InputState extends State<Input> {
  // ignore: prefer_final_fields
  bool _obscureText = false;
  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
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
                      text: widget.label,
                      style:
                          widget.labelStyle ??
                          Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              )
            : Text(
                widget.label,
                style:
                    widget.labelStyle ??
                    Theme.of(context).textTheme.labelMedium,
              ),
        TextFormField(
          autovalidateMode: AutovalidateMode.onUserInteraction,
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
                hintText: "请输入${widget.label}",
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
          validator: (value) {
            if (value == null) return null;
            if (widget.isRequired && value.isEmpty) {
              return "${widget.label}为必填项";
            }
            if (widget.validator != null) {
              return widget.validator?.call(value) ?? "非法输入";
            }
            if (widget.pattern != null && !widget.pattern!.hasMatch(value)) {
              return widget.patternErrorText ?? '格式不正确';
            }
            if (value.length < widget.minLength) {
              return "${widget.label}太短";
            }
            if (value.length > widget.maxLength) {
              return "${widget.label}过长";
            }
            return null;
          },
        ),
      ],
    );
  }
}
