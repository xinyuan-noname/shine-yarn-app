// lib/components/radio_form_field.dart
import 'package:flutter/material.dart';

class Radios<T> extends FormField<T> {
  Radios({
    super.key,
    required String label,
    required String name,
    required List<RadioOption<T>> options,
    TextStyle? labelStyle,
    TextStyle? inputStyle,
    Color? color,
    double? gap,
    bool isRequired = false,
    String? requiredErrorMessage,
    String? Function(T?)? validator,
    super.initialValue,
    super.onSaved,
    AutovalidateMode super.autovalidateMode =
        AutovalidateMode.onUserInteraction,
  }) : super(
         validator: (value) {
           // 1. 必填验证
           if (isRequired && (value == null || _isEmpty(value))) {
             return requiredErrorMessage ?? '$label不能为空';
           }
           // 2. 自定义验证（如果有）
           if (validator != null) {
             return validator(value);
           }
           // 3. 验证通过
           return null;
         },
         builder: (FormFieldState<T> state) {
           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               isRequired
                   ? Text.rich(
                       TextSpan(
                         children: [
                           const TextSpan(
                             text: "*",
                             style: TextStyle(color: Colors.red),
                           ),
                           TextSpan(text: label, style: labelStyle),
                         ],
                       ),
                     )
                   : Text(label, style: labelStyle),
               RadioGroup<T>(
                 groupValue: state.value,
                 onChanged: (value) {
                   state.didChange(value);
                 },
                 child: Column(
                   children: options
                       .map(
                         (opt) => Container(
                           decoration: BoxDecoration(
                             color: color,
                             borderRadius: BorderRadius.circular(12),
                           ),
                           margin: EdgeInsets.only(bottom: 1),
                           child: RadioListTile<T>(
                             value: opt.value,
                             title:
                                 opt.label ??
                                 Text(opt.title, style: inputStyle),
                             contentPadding: EdgeInsets.zero,
                             visualDensity: VisualDensity.compact,
                           ),
                         ),
                       )
                       .toList(),
                 ),
               ),

               if (state.hasError)
                 Padding(
                   padding: const EdgeInsets.only(left: 16, top: 4),
                   child: Text(
                     state.errorText!,
                     style: const TextStyle(color: Colors.red, fontSize: 12),
                   ),
                 ),
               if (gap is double && gap > 0) SizedBox(height: gap),
             ],
           );
         },
       );
  static bool _isEmpty<T>(T? value) {
    if (value == null) return true;
    if (value is String) return value.isEmpty;
    if (value is List) return value.isEmpty;
    return false;
  }

  static Radios<String> gender({
    bool isRequired = false,
    TextStyle? labelStyle,
    TextStyle? inputStyle,
    Color? color,
    double? gap,
  }) {
    return Radios<String>(
      label: '性别',
      name: "gender",
      options: [
        RadioOption<String>(value: "male", title: "男"),
        RadioOption<String>(value: "female", title: "女"),
      ],
      isRequired: isRequired,
      labelStyle: labelStyle,
      inputStyle: inputStyle,
      color: color,
      gap: gap,
    );
  }

  static Radios<bool> comfirm({
    required String label,
    required String name,
    bool isRequired = false,
    TextStyle? labelStyle,
    TextStyle? inputStyle,
    Color? color,
    double? gap,
  }) {
    return Radios<bool>(
      label: label,
      name: name,
      options: [
        RadioOption<bool>(value: true, title: "是"),
        RadioOption<bool>(value: false, title: "否"),
      ],
      isRequired: isRequired,
      labelStyle: labelStyle,
      inputStyle: inputStyle,
      color: color,
      gap: gap,
    );
  }
}

class RadioOption<T> {
  final T value;
  final String title;
  final Widget? label;
  const RadioOption({required this.value, this.label, required this.title});
}
