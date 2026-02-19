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

  const InputProps({
    required this.label,
    required this.name,
    this.color,
    this.validator,
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
    Color? color,
    OutlineInputBorder? border,
    InputDecoration? decoration,
    bool isLast = false,
    AutovalidateMode? autovalidateMode,
    double? gap,
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
      color: color,
      border: border,
      decoration: decoration,
      autovalidateMode: autovalidateMode,
      gap: gap,
    );
  }
  factory InputProps.cnName({
    String label = '姓名',
    String name = 'cnName',
    bool isRequired = false,
    TextStyle? labelStyle,
    Color? color,
    OutlineInputBorder? border,
    InputDecoration? decoration,
    bool isLast = false,
    List<TextInputFormatter>? inputFormatters,
    AutovalidateMode? autovalidateMode,
    double? gap,
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
      color: color,
      border: border,
      decoration: decoration,
      autovalidateMode: autovalidateMode,
      gap: gap,
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
    Color? color,
    OutlineInputBorder? border,
    List<TextInputFormatter>? inputFormatters,
    InputDecoration? decoration,
    bool isLast = false,
    AutovalidateMode? autovalidateMode,
    double? gap,
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
      color: color,
      border: border,
      decoration: decoration,
      autovalidateMode: autovalidateMode,
      gap: gap,
    );
  }
  InputProps copyWith({
    String? label,
    String? name,
    Color? color,
    String? Function(String?)? validator,
    TextStyle? labelStyle,
    OutlineInputBorder? border,
    InputDecoration? decoration,
    int? maxLength,
    int? minLength,
    RegExp? pattern,
    String? patternErrorText,
    bool? isRequired,
    bool? isLast,
    TextInputType? keyboardType,
    bool? autocorrect,
    bool? isPassword,
    List<TextInputFormatter>? inputFormatters,
    AutovalidateMode? autovalidateMode,
  }) {
    return InputProps(
      label: label ?? this.label,
      name: name ?? this.name,
      color: color ?? this.color,
      validator: validator ?? this.validator,
      labelStyle: labelStyle ?? this.labelStyle,
      border: border ?? this.border,
      decoration: decoration ?? this.decoration,
      maxLength: maxLength ?? this.maxLength,
      minLength: minLength ?? this.minLength,
      pattern: pattern ?? this.pattern,
      patternErrorText: patternErrorText ?? this.patternErrorText,
      isRequired: isRequired ?? this.isRequired,
      isLast: isLast ?? this.isLast,
      keyboardType: keyboardType ?? this.keyboardType,
      autocorrect: autocorrect ?? this.autocorrect,
      isPassword: isPassword ?? this.isPassword,
      inputFormatters: inputFormatters ?? this.inputFormatters,
      autovalidateMode: autovalidateMode ?? this.autovalidateMode,
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
  }) {
    return Input.fromProps(
      InputProps(
        label: label,
        name: name,
        color: color,
        validator: validator,
        labelStyle: labelStyle,
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
    AutovalidateMode? autovalidateMode,
    TextEditingController? controller,
    double? gap,
  }) {
    return Input.fromProps(
      InputProps(
        label: label,
        name: name,
        isPassword: true,
        isRequired: isRequired,
        minLength: minLength,
        maxLength: maxLength,
        validator: validator,
        keyboardType: TextInputType.visiblePassword,
        inputFormatters: inputFormatters,
        autocorrect: false,
        isLast: isLast,
        labelStyle: labelStyle,
        color: color,
        border: border,
        decoration: decoration,
        autovalidateMode: autovalidateMode,
        gap: gap,
      ),
      key: key,
      controller: controller,
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
    AutovalidateMode? autovalidateMode,
    TextEditingController? controller,
    double? gap,
  }) {
    return Input.fromProps(
      InputProps.cnName(
        label: label,
        name: name,
        isRequired: isRequired,
        inputFormatters: inputFormatters,
        isLast: isLast,
        labelStyle: labelStyle,
        color: color,
        border: border,
        decoration: decoration,
        autovalidateMode: autovalidateMode,
        gap: gap,
      ),
      key: key,
      controller: controller,
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
    AutovalidateMode? autovalidateMode,
    TextEditingController? controller,
    double? gap,
  }) {
    return Input.fromProps(
      InputProps.number(
        label: label,
        name: name,
        isRequired: isRequired,
        minLength: minLength,
        maxLength: maxLength,
        patternErrorText: patternErrorText,
        inputFormatters: inputFormatters,
        isLast: isLast,
        labelStyle: labelStyle,
        color: color,
        border: border,
        decoration: decoration,
        autovalidateMode: autovalidateMode,
        gap: gap,
      ),
      key: key,
      controller: controller,
    );
  }
}

class _InputState extends State<Input> {
  // ignore: prefer_final_fields
  late bool _obscureText;
  @override
  void initState() {
    super.initState();
    _obscureText = widget.props.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
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
        decoration:
            widget.props.decoration ??
            InputDecoration(
              hintText: "请输入${widget.props.label}",
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
}