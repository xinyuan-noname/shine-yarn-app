import 'package:flutter/material.dart';

class Password extends StatefulWidget {
  final Color? color;
  final String? Function(String?)? validator;
  final TextStyle? labelStyle;
  const Password({super.key, this.color, this.validator, this.labelStyle});

  @override
  State<Password> createState() => _PasswordState();
}

class _PasswordState extends State<Password> {
  String? _errorText;
  bool _obscureText = true;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "密码",
          style: widget.labelStyle ?? Theme.of(context).textTheme.labelMedium,
        ),
        TextField(
          keyboardType: TextInputType.visiblePassword,
          obscureText: _obscureText,
          obscuringCharacter: '•',
          decoration: InputDecoration(
            hintText: "请输入密码",
            errorText: _errorText,
            contentPadding: EdgeInsets.only(left: 10),
            filled: true,
            fillColor:
                widget.color ??
                Theme.of(context).inputDecorationTheme.fillColor,
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(15),
            ),
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

  void _validate(String? value) {
    late String? error;
    if (widget.validator != null) {
      error = widget.validator?.call(value);
    } else {
      final pswdLen = value?.length ?? 0;
      if (pswdLen <= 8) {
        error = "密码太短";
      } else if (pswdLen >= 32) {
        error = "密码过长";
      } else {
        error = null;
      }
    }
    setState(() {
      _errorText = error;
    });
  }
}
