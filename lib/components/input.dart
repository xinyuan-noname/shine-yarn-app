import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InputProps {
  static final TextInputFormatter _textInputFormatterNoEmptyCharacter =
      FilteringTextInputFormatter.deny(RegExp(r"\s"));
  static final TextInputFormatter _textInputFormatterAllowCnNameCharacter =
      FilteringTextInputFormatter.allow(RegExp(r"[\u4e00-\u9fff\u00b7]"));

  final String label;
  final String name;
  final Color? color;
  final TextStyle? labelStyle;
  final TextStyle? inputStyle;
  final TextStyle? hintStyle;
  final OutlineInputBorder? border;
  final InputDecoration? decoration;
  final double? gap;

  final String? Function(String?)? validator;
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

  final Map<String, dynamic>? onSavedMap;

  const InputProps({
    required this.label,
    required this.name,
    this.color,
    this.validator,
    this.inputStyle,
    this.hintStyle,
    this.labelStyle,
    this.border,
    this.decoration,
    this.maxLength = 100,
    this.minLength = 1,
    this.pattern,
    this.patternErrorText,
    this.isRequired = false,
    this.isLast = false,
    this.keyboardType = TextInputType.text,
    this.autocorrect = false,
    this.isPassword = false,
    this.inputFormatters,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.gap,
    this.onSavedMap,
  });

  factory InputProps.password({
    Key? key,
    String label = '密码',
    String name = 'password',
    bool isRequired = false,
    int minLength = 8,
    int maxLength = 32,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextStyle? labelStyle,
    TextStyle? inputStyle,
    TextStyle? hintStyle,
    Color? color,
    OutlineInputBorder? border,
    InputDecoration? decoration,
    bool isLast = false,
    AutovalidateMode? autovalidateMode,
    double? gap,
    Map<String, dynamic>? onSavedMap,
  }) {
    return InputProps(
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
      inputStyle: inputStyle,
      hintStyle: hintStyle,
      color: color,
      border: border,
      decoration: decoration,
      autovalidateMode: autovalidateMode,
      gap: gap,
      onSavedMap: onSavedMap,
    );
  }
  factory InputProps.cnName({
    String label = '姓名',
    String name = 'cnName',
    bool isRequired = false,
    TextStyle? labelStyle,
    TextStyle? inputStyle,
    TextStyle? hintStyle,
    Color? color,
    OutlineInputBorder? border,
    InputDecoration? decoration,
    bool isLast = false,
    List<TextInputFormatter>? inputFormatters,
    AutovalidateMode? autovalidateMode,
    double? gap,
    Map<String, dynamic>? onSavedMap,
  }) {
    return InputProps(
      label: label,
      name: name,
      isRequired: isRequired,
      pattern: RegExp(r"^[\u4e00-\u9fff]+(?:\u00b7[\u4e00-\u9fff]+)*$"),
      patternErrorText: '不是合法的中文名',
      inputFormatters:
          inputFormatters ?? [_textInputFormatterAllowCnNameCharacter],
      isLast: isLast,
      labelStyle: labelStyle,
      inputStyle: inputStyle,
      hintStyle: hintStyle,
      color: color,
      border: border,
      decoration: decoration,
      autovalidateMode: autovalidateMode,
      gap: gap,
      onSavedMap: onSavedMap,
    );
  }
  factory InputProps.number({
    String label = '编号',
    String name = 'number',
    bool isRequired = false,
    int minLength = 1,
    int maxLength = 32,
    String? patternErrorText,
    TextStyle? labelStyle,
    TextStyle? inputStyle,
    TextStyle? hintStyle,
    Color? color,
    OutlineInputBorder? border,
    List<TextInputFormatter>? inputFormatters,
    InputDecoration? decoration,
    bool isLast = false,
    AutovalidateMode? autovalidateMode,
    double? gap,
    Map<String, dynamic>? onSavedMap,
  }) {
    return InputProps(
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
      inputStyle: inputStyle,
      hintStyle: hintStyle,
      color: color,
      border: border,
      decoration: decoration,
      autovalidateMode: autovalidateMode,
      gap: gap,
      onSavedMap: onSavedMap,
    );
  }
}

class Input extends StatefulWidget {
  final InputProps props;
  final TextEditingController? controller;

  const Input._({super.key, required this.props, required this.controller});
  @override
  State<Input> createState() => _InputState();

  factory Input({
    Key? key,
    required String label,
    required String name,
    Color? color,
    String? Function(String?)? validator,
    TextStyle? labelStyle,
    TextStyle? inputStyle,
    TextStyle? hintStyle,
    OutlineInputBorder? border,
    InputDecoration? decoration,
    int maxLength = 100,
    int minLength = 1,
    RegExp? pattern,
    String? patternErrorText,
    bool isRequired = false,
    bool isLast = false,
    TextInputType keyboardType = TextInputType.text,
    bool autocorrect = false,
    bool isPassword = false,
    List<TextInputFormatter>? inputFormatters,
    AutovalidateMode? autovalidateMode,
    TextEditingController? controller,
    double? gap,
    Map<String, dynamic>? onSavedMap,
  }) {
    return Input.fromProps(
      InputProps(
        label: label,
        name: name,
        color: color,
        validator: validator,
        labelStyle: labelStyle,
        inputStyle: inputStyle,
        hintStyle: hintStyle,
        border: border,
        decoration: decoration,
        maxLength: maxLength,
        minLength: minLength,
        pattern: pattern,
        patternErrorText: patternErrorText,
        isRequired: isRequired,
        isLast: isLast,
        keyboardType: keyboardType,
        autocorrect: autocorrect,
        isPassword: isPassword,
        inputFormatters: inputFormatters,
        autovalidateMode: autovalidateMode,
        gap: gap,
        onSavedMap: onSavedMap,
      ),
      key: key,
      controller: controller,
    );
  }
  factory Input.fromProps(
    InputProps props, {
    Key? key,
    TextEditingController? controller,
  }) {
    return Input._(key: key, props: props, controller: controller);
  }
}

class _InputState extends State<Input> {
  late bool _obscureText;
  @override
  void initState() {
    super.initState();
    _obscureText = widget.props.isPassword;
  }

  List<Widget> _buildTextChildren() {
    return [
      widget.props.isRequired
          ? Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: "*",
                    style: TextStyle(color: Colors.red),
                  ),
                  TextSpan(
                    text: widget.props.label,
                    style:
                        widget.props.labelStyle ??
                        Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            )
          : Text(
              widget.props.label,
              style:
                  widget.props.labelStyle ??
                  Theme.of(context).textTheme.labelMedium,
            ),
      TextFormField(
        controller: widget.controller,
        autovalidateMode: widget.props.autovalidateMode,
        keyboardType: widget.props.keyboardType,
        textInputAction: widget.props.isLast
            ? TextInputAction.done
            : TextInputAction.next,
        autocorrect: widget.props.autocorrect,
        inputFormatters: widget.props.inputFormatters,
        obscureText: _obscureText,
        style: widget.props.inputStyle,
        decoration:
            widget.props.decoration ??
            InputDecoration(
              hintText: "请输入${widget.props.label}",
              hintStyle: widget.props.hintStyle,
              contentPadding: const EdgeInsets.only(left: 10),
              filled: true,
              fillColor:
                  widget.props.color ??
                  Theme.of(context).inputDecorationTheme.fillColor,
              border:
                  widget.props.border ??
                  Theme.of(context).inputDecorationTheme.border,
              suffixIcon: widget.props.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
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
        onSaved: widget.props.onSavedMap == null
            ? null
            : (v) {
                if (v != null && v.isNotEmpty) {
                  widget.props.onSavedMap?[widget.props.name] = v;
                }
              },
        validator: (value) {
          if (value == null || value.isEmpty) {
            if (widget.props.isRequired) {
              return "${widget.props.label}为必填项";
            }
            return null;
          } else {
            if (value.length < widget.props.minLength) {
              return "${widget.props.label}太短";
            }
            if (value.length > widget.props.maxLength) {
              return "${widget.props.label}过长";
            }
          }
          if (widget.props.validator != null) {
            return widget.props.validator?.call(value);
          }
          if (widget.props.pattern != null &&
              !widget.props.pattern!.hasMatch(value)) {
            return widget.props.patternErrorText ?? '格式不正确';
          }
          return null;
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = _buildTextChildren();
    if (widget.props.gap != null && widget.props.gap! > 0) {
      children.add(SizedBox(height: widget.props.gap));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

extension InputPropsList on List<InputProps> {
  List<Input> generateAndAssignController(
    Map<String, TextEditingController> map,
  ) {
    final List<Input> list = [];
    for (final item in this) {
      final controller = TextEditingController();
      map[item.name] = controller;
      list.add(Input.fromProps(item, controller: controller));
    }
    return list;
  }

  List<Input> generate() {
    final List<Input> list = [];
    for (final item in this) {
      list.add(Input.fromProps(item));
    }
    return list;
  }
}
