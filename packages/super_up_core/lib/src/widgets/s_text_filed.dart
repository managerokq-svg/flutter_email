import 'package:flutter/material.dart';
import 'package:super_up_core/super_up_core.dart';

class STextField extends StatelessWidget {
  final TextEditingController? controller;
  final String textHint;
  final String? labelText;
  final IconData? icon;
  final TextInputType? inputType;
  final bool obscureText;
  final bool autofocus;
  final int? maxLength;
  final int maxLines;
  final int? minLines;
  final bool autocorrect;
  final Widget? prefix;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const STextField({
    super.key,
    required this.textHint,
    this.controller,
    this.labelText,
    this.icon,
    this.inputType,
    this.prefix,
    this.suffixIcon,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.autofocus = false,
    this.autocorrect = true,
    this.obscureText = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    const accentColor = Color(0xFF007AFF);
    final backgroundColor = isDark
        ? const Color(0xFF1C1C1E).withValues(alpha: 0.6)
        : const Color(0xFFF2F2F7).withValues(alpha: 0.8);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);
    final iconColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.5);
    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.4);
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      obscureText: obscureText,
      maxLength: maxLength,
      maxLines: maxLines,
      minLines: minLines,
      autocorrect: autocorrect,
      autofocus: autofocus,
      onChanged: onChanged,
      validator: validator,
      style: TextStyle(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      cursorColor: accentColor,
      decoration: InputDecoration(
        hintText: textHint,
        labelText: labelText,
        hintStyle: TextStyle(color: hintColor, fontSize: 16),
        labelStyle: TextStyle(color: iconColor, fontSize: 14),
        floatingLabelStyle: const TextStyle(
          color: accentColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: icon != null
            ? Icon(icon, color: iconColor, size: 22)
            : (prefix != null
                ? Container(
                    padding: const EdgeInsets.only(left: 12),
                    child: prefix,
                  )
                : null),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        filled: true,
        fillColor: backgroundColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
