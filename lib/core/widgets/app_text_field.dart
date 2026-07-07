import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType? keyboardType;
  final bool readOnly;
  final bool enabled; // 🚀 Added parameter to handle master layout locks

  const AppTextField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.isPassword = false,
    this.keyboardType,
    this.readOnly = false,
    this.enabled = true, // 🚀 Defaulted to true to preserve safety across sibling screens
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          readOnly: readOnly,
          enabled: enabled, // 🚀 Injected here to manage the internal input lock states
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            // 🎨 UX Update: Shifts background color dynamically when locked
            fillColor: enabled ? Colors.white : Colors.grey.shade100, 
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            // Style the disabled border state specifically to match card alignment boundaries
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
          ),
        ),
      ],
    );
  }
}